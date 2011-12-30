#!/usr/bin/sh

#Requirement
## later Ruby1.8.7
## Grit (gem install grit)

#これはpreviewサーバです
#ローカルで編集した内容を確認する際に利用します
#http://127.0.0.1:8888/index.cgi にアクセスすると、情報を確認できます

ruby preview_server.rb 127.0.0.1 8888 .
