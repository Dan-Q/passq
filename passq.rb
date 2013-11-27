#!/usr/bin/ruby
require 'rubygems'
require 'bundler'
Bundler.require

class Passq < Sinatra::Base
  configure :production, :development do
    enable :logging
  end
  configure :development do
    register Sinatra::Reloader
  end
  set :haml, :format => :html5

  get '/' do
    "hi"
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
