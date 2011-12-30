require 'wiki_parser'
require 'find'
require 'kconv'
require 'settings'

class DataStore
  def initialize(settings, repository_path)
    @path = repository_path.sub(/\/$/,"")
    @settings = settings
    site_address = @settings.setting('SiteAddress').sub(/\/$/,"")
    index_handler = @settings.setting('IndexHandler')
    cache_dir = @settings.setting('CacheDirectory')
    @parser = WikiParser.new(site_address, index_handler, cache_dir)
  end
end

