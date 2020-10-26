#! /usr/bin/env ruby

require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'yaml'
require 'pry' if development?
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

helpers do
  # Returns array of most frequent contacts
  def most_frequent_contacts(max)

    frequent_ids = session[:tally].sort_by {|k,v| -v.to_i}.take(max).to_h.keys

    frequent_ids.map do |id|
      @list.find {|contact| contact[:guid] == id}
    end.compact
  end
end

before do
  @list = load_data
  session[:tally] = {} unless session[:tally]
end

# Returns next available GUID
def generate_guid
  list = load_data

  max = list.max_by{|hash| hash[:guid]}
  max ? max[:guid].next : '1'
end

# Returns instance variable to populate group dropdown box in template
def group_drop_down
  @groups = @list.map { |hash| hash[:group] }.uniq.compact
end

# Updates the number of times a contact was accessed
def update_tally(guid)
  session[:tally][guid] ? session[:tally][guid] += 1 : session[:tally][guid] = 1 
end

# Passes @list to index to display all contacts
get "/" do
  @filter_for_group = params[:group]

  # To populate filter dropdown menu
  group_drop_down

  if @filter_for_group
    @list.select! { |contact| contact[:group] == @filter_for_group }
  end

  erb :index
end

# Returns form to create or edit a contact
get "/create" do
  group_drop_down
  @contact_info = {}
  erb :create_contact
end

# Page to display individual contact
get "/:id" do
  guid = params[:id]

  update_tally(guid)

  @contact_info = @list.find { |contact| contact[:guid] == guid }

  erb :contact
end

get "/:id/edit" do
  guid = params[:id]
  @contact_info = @list.find { |contact| contact[:guid] == guid }
  group_drop_down
  erb :create_contact
end


# Creates or modifies a contact
post "/contact" do

  guid = params[:guid]

  new_contact = {
    guid: guid || generate_guid,
    first_name: params[:first_name],
    last_name: params[:last_name],
    group: params[:group]
  }
  
  match = @list.find {|contact| contact[:guid] == guid }
  
  if match
      match.merge!(new_contact)
  else
    @list << new_contact
  end
  
  save_data(@list)

  redirect "/"
end
