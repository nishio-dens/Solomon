require 'wiki_plugin'
require 'data_store'

class Toc
  def initialize
    @settings = Settings.new('settings.config')
    if @settings.setting('Git')
      @store = GitDataStore.new(@settings, @settings.setting('GitRepository'), @settings.setting('GitBare'))
    else
      @store = LocalDataStore.new(@settings, @settings.setting('LocalDataStorePath'))
    end
    site_address = @settings.setting('SiteAddress').sub(/\/$/,"")
    index_handler = @settings.setting('IndexHandler')
    @url = "#{site_address}/#{index_handler}?"
  end

  def output(args)
    tocfile = args.chomp
    file = @store.contents(tocfile)
    buf = []
    if file
      hdata = file.toutf8.rstrip.split(/\r?\n/).select{|d| d =~ /\A\*/}
      current_level = 0 
      num = 1
      hdata.each do |d|
        if d =~ /\A(\*+)\s*(.*)/
          name = $2
          level = $1.length 
          if level > current_level
            (level - current_level).times{buf << "<ul>"}
          elsif level < current_level
            (current_level - level).times{buf << "</ul>"}
          end
          current_level = level
          buf << "<li><a href=\"#{@url}#{tocfile}\##{num}\">#{name}</a></li>"
          num += 1
        end
      end
      current_level.times{buf << "</ul>"}
    end
    buf.join("\n")
  end

  private

  def list(lines, marker)
    buf = ["<ul>"]
    until lines.empty?
      buf << "<li>#{parse_inline(lines.first.sub(/\A-+\s*/,''))}</li>"
      mk = lines.shift[/\A(-{1,3})/,1]
      mk = /\A#{Regexp.escape(mk)}[^#{Regexp.escape(mk)}]/
      sub = take_paragraph_block(lines, mk)  
      buf << parse_list(sub, mk) unless sub.empty?
    end
    buf << "</ul>"
    buf
  end

end

WikiPlugin.register :toc do
  plugin_name 'Table of Contents'
  plugin_version 1.0
  plugin_description 'Table Of Contentsを出力します'

  macro :toc do |args|
    Toc.new.output(args)
  end
end
