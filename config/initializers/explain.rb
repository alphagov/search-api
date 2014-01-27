# This file can be overwritten on deployment

set :enable_explain, ENV["RACK_ENV"] == "development"
