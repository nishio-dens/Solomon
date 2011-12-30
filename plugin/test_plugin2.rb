require 'wiki_plugin'

WikiPlugin.register :test_plugin2 do
  plugin_name 'test plugin 2'
  plugin_version '0.1'
  macro :func2 do |args|
    "test plugin2 fuction argument=#{args}"
  end
end


