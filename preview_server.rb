require 'webrick'
require 'settings'

class PreviewServer
  def initialize(ip, port, document_root)
    @ip = ip
    @port = port
    @server = WEBrick::HTTPServer.new({:DocumentRoot => document_root, :BindAddress => @ip, :Port => @port})
    @settings = Settings.new('settings.config')
  end

  def server_handler(server)
    handler_list = @settings.setting('Handler')
    if handler_list
      handler_list.each_pair do |k,v|
        server.mount("/#{k}", WEBrick::HTTPServlet::CGIHandler, "#{v}")
      end
    end
  end

  def start
    server_handler(@server)
    trap(:INT){ @server.shutdown }
    @server.start
  end
end

if ARGV.length >= 3 
  PreviewServer.new(ARGV[0],ARGV[1],ARGV[2]).start
else
  puts "Usage ruby PreviewServer IP Port DocumentRoot"
end
