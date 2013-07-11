# This file can be overwritten on deployment

set :enable_queue, ! ENV["ENABLE_QUEUE"].nil?
