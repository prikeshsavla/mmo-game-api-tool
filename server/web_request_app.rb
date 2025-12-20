require 'open-uri'
require 'json'

class WebRequestApp
  def call(env)
    puts env
    body = env['rack.input'].string
    puts body
    [200, { 'Content-Type' => 'application/json' }, [body]]
  end
end
