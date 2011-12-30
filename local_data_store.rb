require 'wiki_parser'
require 'find'
require 'kconv'
require 'data_store'

class LocalDataStore < DataStore
  def initialize(settings, repository_path)
    super(settings, repository_path)
  end

  def list
    file_list = {}
    d = @path 
    Find.find(d) do |file|
      if !File.directory?(file)
        File::open(file) do |f|
          buf = [] 
          while (line = f.gets) =~ /\A#/
            buf << line.toutf8.chomp 
          end
          info = @parser.info(buf)
          if !info['Date']
            info['Date'] = File.stat(file).mtime.strftime("%Y-%m-%d")
          end
          file_list[file.gsub("#{d}/",'')] = info
        end
      end
    end
    file_list
  end

  def contents(path)
    begin
      data = File.read("#{@path}/#{path}")
    rescue 
      data = "file not found"
    end
    data
  end

  def cache(path, filename)
    begin
      data = contents(path)
      cache_dir = @settings.setting('CacheDirectory')
      cache_dir.sub!(/\/$/,"") if cache_dir
      open("#{cache_dir}/#{filename}", "w") {|dest| dest.write(data)} if data
    rescue 
    end
  end

end

