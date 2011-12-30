require 'wiki_plugin'

class TestConverter
  def convert(text)
    "Test Converter #{text}"
  end
end

WikiPlugin.register :test_plugin do
  plugin_name 'test plugin'
  plugin_version '1.0'
  plugin_description 'this is a test plugin'
  macro :test_function do |args|
    TestConverter.new.convert("aiueo")
  end
end

