#!/usr/bin/ruby 

require 'cgi'
require 'settings'
require 'erb'
require 'kconv'
require 'find'

#command一覧
require 'command/view_command'
require 'command/error_command'
require 'command/search_command'

class Page 

  def initialize
    #設定ファイル読み込み
    @settings = Settings.new('settings.config')
    @cgi = CGI.new(:accept_charset => @settings.setting('Encoding'))
    @command = {'view' => ViewCommand, 'error' => ErrorCommand, 'search' => SearchCommand}
    @default_command = 'view'
    navi = @settings.setting('GlobalNavi')
    if navi
      @global_navi = []
      navi.each do |navi_data|
        @global_navi << {:name => navi_data['name'], :address => navi_data['address']}
      end
    end
  end

  def html
    #header部分
    print @cgi.header('type' => "text/html")
    #読み込むwikiファイル名取得
    filename = 
      case @cgi.params.keys.size
      when 0
        @settings.setting('FrontPage')
      when 1
        @cgi.params.keys[0]
      else
        @cgi.params['page'][0] ? @cgi.params['page'][0] : nil
      end
    @cgi.params['page'] = [filename]
    #command
    cmd = @cgi.params['c'][0]
    if cmd
      if @command[cmd]
        handler = @command[cmd].new(@settings, @cgi.params)
      else
        handler = @command['error'].new(@settings, @cgi.params)
      end
    else
      handler = @command[@default_command].new(@settings, @cgi.params) 
    end
    #読み込むテンプレート
    template = handler.template 
    #埋め込む情報
    @contents = handler.contents
    #erb表示
    erb = ERB.new(File.read(template))
    puts erb.result(binding)
  end

end

data = Page.new
data.html
