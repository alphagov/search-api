require "test/unit"
%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require "simplecov"
SimpleCov.start
