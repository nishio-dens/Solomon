require 'yaml'

class Settings

  attr_reader :filename
  
  def initialize(filename)
    @filename = filename
    @store = YAML.load_file(filename) 
  end

  def setting(key)
    @store[key]
  end

end 

