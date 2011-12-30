require 'wiki_plugin'
require 'find'
require 'cgi'

class WikiParser

  #wiki解析中に見つけた、cacheすべきデータ
  attr_reader :cache_files

  def initialize(base_url, index_handler, cache_dir = nil)
    Find.find('plugin') do |file|
      if !File.directory?(file)
        if file =~ /.*\.rb$/
          require file
        end
      end
    end
    @base_url = base_url
    @index_handler = index_handler
    @cache_dir = cache_dir
    @cache_files = []
  end
  
  def to_html(src, jumplist = false)
    @jump = jumplist
    @jump_index = 0 if @jump
    parse(src.toutf8.rstrip.split(/\r?\n/).map{|line| line.chomp})
  end

  def info(lines)
    info = {}
    while lines.first
      case lines.first
      when ''
        lines.shift
      when /\A#\+/
        k, v = parse_info(lines.shift)
        info[k] = v
      else
        lines.shift
      end
    end
    info
  end

  def parse(lines)
    buf = []
    while lines.first
      case lines.first
      when ''
        lines.shift
      when /\A#/
        lines.shift
      when /\A----/
        lines.shift
        buf << '<hr />'
      when /\A\*/
        marker = lines.first[/\A(\*{1,4})/,1]
        marker = /\A#{Regexp.escape(marker)}[^#{Regexp.escape(marker)}]/
        buf << parse_h(lines.shift)
        buf << "<div class=\"chapter\">"
        buf << parse(take_paragraph_block(lines, marker))
        buf << "</div>"
      when /\A>>/
        lines.shift
        marker = /\A<</
        buf << "<blockquote>"
        buf << parse(take_paragraph_block(lines, marker))
        lines.shift 
        buf << "</blockquote>"
      when /\A>\|/
        lines.shift
        marker = /\A\|</
        buf << "<pre>"
        buf << CGI.escapeHTML(take_paragraph_block(lines, marker).join("\n"))
        lines.shift 
        buf << "</pre>"
      when /\A-/
        buf << parse_list("ul", take_block(lines,/\A-/), nil)
      when /\A\+/
        buf << parse_list("ol", take_block(lines,/\A\+/), nil)
      when /\A\|/
        buf << "<table>"
        buf << parse_table(take_block(lines,/\A\|/))
        buf << "</table>"
      when /\A\{\{.*\}\}/
        c = lines.first[/\A\{\{(.*)\}\}/, 1] 
        if c =~ /(\w+)\((.*)\)/
          name, args = $1, $2
          buf << WikiPlugin.exec_macro(name, args)
        end
        lines.shift
      else
        buf << "<p>"
        buf << parse_paragraph(take_paragraph_block(lines, /^\s*$/)).join("\n")
        buf << "</p>"
      end
    end
    buf.join("\n")
  end

  private

  def take_paragraph_block(lines, marker)
    buf = []
    until lines.empty?
      break if lines.first =~ marker 
      buf << lines.shift
    end
    buf
  end

  def take_block(lines, marker)
    buf = []
    until lines.empty?
      break unless marker =~ lines.first
      buf << lines.shift
    end
    buf
  end

  def parse_info(line)
    if line =~ /#\+\s*(\w+):\s*(.*)/
      return $1, $2
    end
    nil
  end

  def parse_list(type, lines, marker)
    buf = ["<#{type}>"]
    until lines.empty?
      buf << "<li>#{parse_inline(lines.first.sub(/\A[-|\+]+\s*/,''))}</li>"
      mk = lines.shift[/\A([-|\+]{1,3})/,1]
      mk = /\A#{Regexp.escape(mk)}[^#{Regexp.escape(mk)}]/
      sub = take_paragraph_block(lines, mk)  
      buf << parse_list(type, sub, mk) unless sub.empty?
    end
    buf << "</#{type}>"
    buf
  end

  def parse_table(lines)
    buf = []
    lines.each do |d|
      buf << "<tr>"
      element = d.split(/\|/)
      element.shift
      element.each do |v| 
        v.strip!
        if v =~ /\A\*/
          v.sub!(/\A\*/,'')
          buf << "<th>#{v}</th>"
        else
          buf << "<td>#{v}</td>" 
        end
      end
      buf << "</tr>"
    end
    buf
  end

  def parse_paragraph(lines)
    lines.map{|line| parse_inline(line)}
  end

  def parse_h(line)
    level = line.slice(/\A\*{1,4}/).length
    title = line.sub(/\A\*+\s*/,'')
    @jump_index = @jump_index + 1 if @jump
    ret = "<h#{level + 1}>#{parse_inline(title)}</h#{level + 1}>"
    ret += "<a name=\"#{@jump_index}\"></a>" if @jump
    ret
  end

  def parse_inline(str)
    str = CGI.escapeHTML(str)
    @re ||= %r<
        \[\[(.+?):\s*(https?://\S+)\s*\]\]  #label & URL $1,$2
      | (https?://\S+)                      #URL $3
      | \[\[(.+?):\s*(.+\.[txt|wiki]\S+)\s*\]\]  #label & wikipage(.txt|.wiki) $4,$5
      | \[\[(.+?):\s*(.+\.[png|PNG|jpg|JPG|gif|GIF]\S+)\s*\]\]  #label & image $6,$7
      | \[\[(.+?):\s*(.+\S+)\s*\]\]              #label & other files $8,$9
      | ''(.+?)''                           #Bold $10
      | &quot;&quot;(.+?)&quot;&quot;       #italic $11
      | &lt;del&gt;(.+?)&lt;/del&gt;        #delete line $12 (<del>...</del>)
    >x
    str.gsub(@re) do
      case
      when bracket = $1 then a_href($2, bracket)
      when url = $3 then a_href(url, url)
      when pagelabel = $4 then a_href("#{@base_url}/#{@index_handler}?#{$5}", pagelabel)
      when imagelabel = $6 then
        source = $7
        label_option = imagelabel.split(/,/)
        label = label_option.shift if label_option
        image_cache(source, label, label_option)
      when filename = $8 then a_href("#{$9}", filename)
      when boldlabel = $10 then bold(boldlabel)
      when italiclabel = $11 then italic(italiclabel)
      when deletelabel = $12 then delete_line(deletelabel)
      end
    end
  end

  def a_href(url, label)
    "<a href=\"#{url}\">#{label}</a>"
  end

  def bold(label)
    "<b>#{label}</b>"
  end

  def italic(label)
    "<i>#{label}</i>"
  end

  def delete_line(label)
    "<s>#{label}</s>"
  end

  def image_cache(source, alt, options)
    #cacheに保存する際、/を_に変換する(content/test.png to content_test.png)
    cache_source = source.sub(/\//,'_').chomp if source
    @cache_files << [source, cache_source] 
    options.map!{|v| CGI.escapeHTML(v)}
    "<img src=\"#{@base_url}/#{@cache_dir}/#{cache_source}\" alt=\"#{alt}\" #{options.join(" ") if options}>"
  end

end
