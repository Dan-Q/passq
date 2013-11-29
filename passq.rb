#!/usr/bin/env ruby
require 'rubygems'
require 'bundler'
Bundler.require

# Directory in which password safes are stored
PASSWORD_STORE_DIR = 'password-store'

# Static salt setup
# We use a static salt (per installation) to hash the hashes of the account_keys,
# because we need to be able to find them in the filesystem without any other
# point of reference.
# This is reasonably safe, because we're only protecting the hashes to prevent an
# attacker with temporary server access from being able to request encrypted password
# safes after their access is revoked, by replaying the authentication. It doesn't
# affect the encryption of the safes themselves.
STATIC_SALT_FILE = "#{PASSWORD_STORE_DIR}/static-salt"
if File::exists?(STATIC_SALT_FILE)
  STATIC_SALT = File::read(STATIC_SALT_FILE)
else
  # Generate a salt
  STATIC_SALT = BCrypt::Engine.generate_salt
  File::open(STATIC_SALT_FILE, 'w'){ |f| f.print STATIC_SALT }
  # TODO: suggest that server admin protects the static salt
end

BCRYPT_COST = 10 # how heavily are the filenames of the accounts hashed

# Accounts contain only encrypted data (decryption happens client-side, in Javascript),
# and are identified by an 'account key', comprised of a hash of the username and password.
# In the filesystem, account keys are hashed (again) using a static salt (so they can be
# looked up without inspecting each file), which prevents re-authentication by a
# formerly-privileged attacker.
class Account
  attr_accessor :encrypted_password_safe
  attr_reader :is_new

  # Returns true if accounts exist, false otherwise
  def self.any?
    Dir::new(PASSWORD_STORE_DIR).any?{ |f| f =~ /^[a-z0-9]{120}\.safe$/}
  end

  # Find or create the specified account
  def initialize(account_key, create_with_contents = nil)
    @account_key = account_key
    if File::exists?(self.filename)
      @encrypted_password_safe = File::read(self.filename)
    elsif create_with_contents
      @encrypted_password_safe = create_with_contents
      @is_new = true
      self.save
    else
      raise 'Account not found.'
    end
  end

  # Returns the generated filename of the account, based on its account key
  # This is formed by hashing the account key using BCrypt and a static salt, for the reasons
  # described above, and then by converting the resulting bytes to hexatridecimal to get a
  # filename that'll be friendly across all operating systems
  # (there's certainly a more-efficient way to do this, but we don't necessarily NEED efficiency)
  def filename
    return @filename if @filename # caching
    hashed_account_key = BCrypt::Engine.hash_secret(@account_key, STATIC_SALT).bytes.collect{|i|i.to_s(36)}.join
    @filename = "#{PASSWORD_STORE_DIR}/#{hashed_account_key}.safe"
  end

  # Save the account. Returns the account, for chaining.
  def save
    File::open(self.filename, 'w'){ |f| f.print @encrypted_password_safe }
    self
  end
end

class Passq < Sinatra::Base
  configure :production, :development do
    enable :logging
  end
  configure :development do
    register Sinatra::Reloader
  end
  set :haml, :format => :html5

  get '/' do
    return haml(:'first-login') if !Account::any? # Show "first-login" page if needed
    haml :login
  end

  post '/setup' do
    return 'Not in setup mode.' if Account::any?
    account = Account::new(params[:account_key], params[:empty_password_safe])
    if account.is_new
      'OK'
    else
      'Something went wrong.'
    end
  end

  post '/login' do
    return '' unless (account = Account::new(params[:account_key]))
    account.encrypted_password_safe
  end

  get '/app' do
    haml :app
  end

  post '/save' do
    return 'Authentication failed.' unless (account = Account::new(params[:account_key]))
    return 'Save data not provided.' if !params[:encrypted_password_safe]
    # TODO: backups, etc.
    account.encrypted_password_safe = params[:encrypted_password_safe]
    account.save
    'OK'
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
