require_relative 'server/web_server'

APP = WebRequestApp

SERVER = SingleThreadedServer

SERVER.new(APP.new).start
