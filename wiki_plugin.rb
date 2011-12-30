require 'settings'

class WikiPlugin
  @plugins = {}
  @macros = {}

  attr_accessor :name, :version, :author, :url, :description

  class << self
    attr_reader :plugins, :macros

    def register(plugin_name, &block)
      p = WikiPlugin.new(plugin_name)
      p.instance_eval(&block)
      p.name = @@name
      p.version = @@version
      p.description = @@desc
      p.author = @@author 
      p.url = @@url
      @@name, @@version, @@desc, @@author, @@url = nil
      WikiPlugin.plugins[plugin_name] = p 
    end

    def exec_macro(name, args)
      if @macros.has_key?(name.to_sym)
        @macros[name.to_sym].call(args)
      else
        'Error: Undefined Method'
      end
    end

  end

  def initialize(plugin_name)
    @plugin_name = plugin_name.to_sym
    @@name, @@version, @@desc, @@author, @@url = nil
    @settings = Settings.new('settings.config')
  end

  private
  def macro(function_name, &block)
    WikiPlugin.macros[function_name] = block
  end

  def plugin_description(description)
    @@desc = description
  end

  def plugin_name(txt)
    @@name = txt
  end

  def plugin_version(txt)
    @@version = txt
  end

  def plugin_author(txt)
    @@author = txt
  end

  def plugin_url(txt)
    @@url = txt
  end

end
