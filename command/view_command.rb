require 'settings'
require 'cgi'
require 'data_store'
require 'local_data_store'
require 'git_data_store'
require 'wiki_parser'

class ViewCommand
  attr_reader :template

  def initialize(settings, params)
    @template = 'template/main.erb'
    @settings = settings
    site_address = @settings.setting('SiteAddress').sub(/\/$/,"")
    index_handler = @settings.setting('IndexHandler')
    cache_dir = @settings.setting('CacheDirectory')
    @parser = WikiParser.new(site_address, index_handler, cache_dir)
    @params = params
    if @settings.setting('Git') 
      @store = GitDataStore.new(@settings, @settings.setting('GitRepository'), @settings.setting('GitBare'))
    else
      @store = LocalDataStore.new(@settings, @settings.setting('LocalDataStorePath'))
    end
    @page = params['page']
  end

  def contents
    c = {}
    begin
      #TODO: 後でファイルから読み込むようにする
      c[:Title] = "#{@settings.setting('SiteName')} | #{@page}"
      c[:SiteName] = @settings.setting('SiteName')
      c[:Description] = @settings.setting('Description')
      side = @store.contents("#{@settings.setting('SideMenu')}")
      c[:SideContents] = side ? @parser.to_html(side) : "" 
      mc = @store.contents("#{@page}")
      c[:MainContents] = mc ? @parser.to_html(mc, true) : nil 
      #cache download
      @parser.cache_files.each do |files|
        @store.cache(files[0], files[1])
      end
    rescue => e 
      Logger.new(STDOUT).error(e) 
    end
    c
  end
end
