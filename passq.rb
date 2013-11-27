#!/usr/bin/env ruby
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

  PASSWORD_STORE_DIR = 'password-store'

  before do
    # Preload credentials if set
    if File::exists?("#{PASSWORD_STORE_DIR}/credentials")
      @credentials = File::read("#{PASSWORD_STORE_DIR}/credentials").strip
    end
  end

  get '/' do
    return haml(:'first-login') unless !!@credentials # Show "first-login" page if needed
    haml :login
  end

  post '/setup' do
    if !@credentials || !!params[:account_key] # So long as we don't already have stored credentials and do have an account key, proceed
      File::open("#{PASSWORD_STORE_DIR}/credentials", 'w') do |f|
        f.print params[:account_key]
      end
      File::open("#{PASSWORD_STORE_DIR}/password_safe", 'w') do |f|
        f.print params[:empty_password_safe]
      end
    end
    "window.location.href = '/';"
  end

  post '/login' do
    if !@credentials || @credentials != params[:account_key]
      return ''
    end
    File::read("#{PASSWORD_STORE_DIR}/password_safe")
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
