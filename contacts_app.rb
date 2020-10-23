#! /usr/bin/env ruby

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

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data/contacts.yml', __FILE__)
  else
    File.expand_path('../data/contacts.yml', __FILE__)
  end
end

def load_data
  YAML.load_file(data_path) || []
end

def save_data(data)
  File.open(data_path, 'w') do |file|
    file.write(YAML.dump(data))
  end  
end

before do
  @list = load_data
end

# Returns next available GUID
def generate_guid
  list = load_data

  max = list.max_by{|hash| hash[:guid]}
  max ? max[:guid] + 1 : 1
end


get "/" do
  erb :index
end

# Returns form to create new contact
get "/create" do

  @groups = @list.map do |hash|
    hash[:group]
  end

  erb :create_contact
end

# Creates new contact
post "/contact" do
  @list << {
    guid: generate_guid,
    first_name: params[:first_name],
    last_name: params[:last_name],
    group: params[:group]
  }

  save_data(@list)

  redirect "/"
end
