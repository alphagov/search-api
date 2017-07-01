$LOAD_PATH << './lib' << './'
require 'rspec'
require 'pry'

class TestUnitLoader
  def initialize(path)
    $LOAD_PATH << path

    if ARGV[0] =~ /_(spec|test).rb/
      load ARGV[0]
    else
      # puts path
      Dir["#{path}/**/*_test.rb"].each do |path|
        puts "loading: #{path}"
        load path
      end
    end

    build_specs
  end

  def build_specs
    ObjectSpace.each_object(::Class).select do |klass|
      klass < MiniTest::Unit::TestCase
    end.each do |klass|
      # binding.pry
      RSpec.describe klass.to_s do
        i = klass.new
        klass.public_instance_methods.grep(/^test_/).map do |method_name|
          p = klass.instance_method(method_name).bind(i)
          it method_name do
            i.spec = self
            p.call
          end
        end
      end
    end
  end
end

module MiniTest
  module Unit
    class TestCase
      attr_accessor :spec

      def assert_equal(a, b)
        spec.expect(a).to spec.eq(b)
      end

      def assert_match(p, a)
        spec.expect(a).to spec.match(p)
      end

      def assert_raises(error, &proc)
        error_instance = nil
        spec.expect do
          begin
            proc.call
          rescue Exception => e
            error_instance = e
            raise
          end
        end.to spec.raise_error(error)
        error_instance
      end

      def refute(a)
        spec.expect(a).to spec.be_falsey
      end

      def refute_includes(a, b)
        spec.expect(a).not_to spec.includes(b)
      end

    end
  end
end

# shoulda-context helpers
module ShouldaForRspec
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
  end
end


RSpec.configure do |c|
  c.mock_with :mocha

  # c.before(:all) do
  #   binding.pry
  #   TestUnitLoader.build_spec
  # end
end

puts 'starting...'
TestUnitLoader.new(File.join(__dir__, 'unit_test_migration'))
