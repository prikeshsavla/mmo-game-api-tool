require_relative 'server/web_server'
require_relative 'server/web_request_app'

APP = WebRequestApp

SERVER = SingleThreadedServer

SERVER.new(APP.new).start
