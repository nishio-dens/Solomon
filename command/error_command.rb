require 'settings'
require 'cgi'
require 'data_store'
require 'local_data_store'
require 'git_data_store'
require 'wiki_parser'

class ErrorCommand
  attr_reader :template
  
  def initialize(settings, params)
    @template = 'template/error.erb'
    @settings = settings
    @params = params
  end

  def contents
    content = {:MainContents => "Commandが見つかりませんでした"}
    content
  end

end
