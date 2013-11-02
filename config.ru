#!/usr/bin/env ruby
# config.ru

require "rack"
require "oauth2"

class App 
  def initialize key, secret, site
    @client = OAuth2::Client.new key, secret, site: site
  end 

  def call(env)
    req = Rack::Request.new(env)
    case req.path_info
    when "/"        ; redirect_to_authorize_url(req)
    when "/callback"; render_json(req)
    else            ; redirect_to_root_url(req)
    end 
  end 

  private

  def redirect_to_root_url req 
    redirect "#{req.scheme}://#{req.host_with_port}/"
  end 

  def redirect_to_authorize_url req 
    redirect @client.auth_code.authorize_url(redirect_uri: callback_url(req))
  end 

  def render_json req 
    code = req.GET["code"]
    token = @client.auth_code.get_token(code, redirect_uri: callback_url(req))
    json = token.get("/api/v1/foo.json").body
    [ 200, { "Content-Type" => "application/json" }, [json] ]
  end 

  def redirect url; [ 302, { "Location" => url }, [] ]; end 

  def callback_url req
    "#{req.scheme}://#{req.host_with_port}/callback"
  end 
end

run App.new(ENV["KEY"], ENV["SECRET"], ENV["SITE"])
