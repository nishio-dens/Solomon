require 'wiki_parser'
require 'rubygems'
require 'grit'
require 'data_store'
require 'kconv'

class GitDataStore < DataStore
  def initialize(settings, repository_path, bare = nil)
    super(settings, repository_path)
    if bare 
      ENV['PATH'] = "" #Gritのバグのため
      @repo = Grit::Repo.init_bare(repository_path)
    else
      @repo = Grit::Repo.new(repository_path)
    end
  end

  def list(current_dir = nil, contents = nil)
    file_list = {}
    c = contents.nil? ? @repo.tree.contents : contents
    c.each do |d|
      cname = "#{current_dir if current_dir}#{d.name}"
      if d.is_a?(Grit::Tree)
        file_list.merge!(list("#{cname}/", d.contents))
      elsif d.is_a?(Grit::Blob)
        info = @parser.info(d.data.toutf8.split("\n"))
        if !info['Date']
          info['Date'] = @repo.commits.first.committed_date.strftime("%Y-%m-%d") 
        end
        file_list[cname] = info 
      end
    end
    file_list
  end

  def contents(path)
    file = @repo.tree/path
    file.data if file
  end

  def cache(path, filename)
    begin
      data = contents(path)
      cache_dir = @settings.setting('CacheDirectory')
      cache_dir.sub!(/\/$/,"")
      open("#{cache_dir}/#{filename}", "w") {|dest| dest.write(data)} if data
    rescue
    end
  end
end

