require "test/unit"
%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require "simplecov"
require "simplecov-rcov"
SimpleCov.start
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
