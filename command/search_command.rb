require 'settings'
require 'cgi'
require 'data_store'
require 'local_data_store'
require 'git_data_store'
require 'wiki_parser'
require 'kconv'

class SearchCommand
  attr_reader :template
  
  def initialize(settings, params)
    @template = 'template/search.erb'
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
    @key = params['key'][0]
    @key = @key.toutf8 if @key
  end

  def contents
    content = {}
    content[:Title] = "#{@settings.setting('SiteName')} | Search "
    content[:SiteName] = @settings.setting('SiteName')
    content[:Description] = @settings.setting('Description')
    side = @store.contents("#{@settings.setting('SideMenu')}")
    content[:SideContents] = side ? @parser.to_html(side) : "" 
    result = @key ? output_result(@key) : nil
    content[:Result] = result 
    content[:Keyword] = @key
    content[:ResultNum] = result ? result.size : 0
    content[:SiteAddress] = @settings.setting('SiteAddress').sub(/\/$/,"")
    content[:IndexHandler] = @settings.setting('IndexHandler')
    content
  end

  private
  def search(keyword)
    list = []
    reg = keyword.chomp.sub(' ','|')
    @store.list.each_pair do |k,v| 
      include_lines = @store.contents(k).select{|x| x =~ /#{reg}/i}
      if include_lines.size > 0 && v['Title']
        list << [k,v, include_lines] 
      end
    end
    list
  end

  def output_result(keyword)
    site_address = @settings.setting('SiteAddress')
    site_address.sub!(/\/$/,"")
    address = "#{site_address}/#{@settings.setting('IndexHandler')}"
    files = search(keyword)
    result = files.map do |d|
      { :address => "#{address}?#{d[0]}",
        :title => d[1]['Title'].to_s, 
        :date => d[1]['Date'].to_s,
        :snippet => d[2][0].to_s}
    end
  end

end
