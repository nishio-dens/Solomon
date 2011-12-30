require 'wiki_plugin'
require 'data_store'

class Recent
  def initialize
    @settings = Settings.new('settings.config')
    if @settings.setting('Git')
      @store = GitDataStore.new(@settings, @settings.setting('GitRepository'), @settings.setting('GitBare'))
    else
      @store = LocalDataStore.new(@settings, @settings.setting('LocalDataStorePath'))
    end
  end

  def output(args)
    num = args.chomp.to_i
    buf = []
    file_list = recent_list(@store.list, args.to_i)
    file_list.sort.reverse.each do |k,v|
      buf << "<h5>#{k}</h5>"
      buf << "<ul>"
      v.each do |info|
        buf << "<li><b>"
        buf << "<a href=\"#{@settings.setting('IndexHandler')}?#{info[1]}\">#{info[0]}</a></b></li>"
      end
      buf << "</ul>"
    end
    buf.join("\n")
  end

  private
  #key = 日時, value = [Title, FilePath]のリストを返す
  def recent_list(file_list, num = 100)
    list = {}
    cnum = 0
    file_list.each_pair do |k,v|
      d = v['Date']
      if d && v['Title']
        list[d] ||= []
        list[d] << [v['Title'], k]
        cnum += 1
        break if cnum >= num
      end
    end
    list
  end
end

WikiPlugin.register :recent do
  plugin_name 'recent'
  plugin_version '1.0'
  plugin_description '最近編集したファイル一覧を出力します'

  macro :recent do |args|
    Recent.new.output(args)
  end
end
