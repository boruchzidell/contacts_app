#! usr/bin/env ruby

require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'yaml'

configure do
  set :sessions, expire_after: 365*24*60*60
  set :session_secret, 'secret'
end
