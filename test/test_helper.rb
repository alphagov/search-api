ENV['RACK_ENV'] = 'test'

require "test/unit"
require "rack/test"
%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require "simplecov"
require "simplecov-rcov"
SimpleCov.start
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
