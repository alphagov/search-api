$LOAD_PATH << './lib' << './'
require 'rspec'
require 'pry'

require 'webmock/rspec'

class TestUnitLoader
  def initialize(path)
    $LOAD_PATH << path

    if ARGV[0] =~ /_test.rb$/

      top_level = ::RSpec::Core::DSL.top_level
      called_by = []
      changes = Proc.new do
        define_method(:describe) do |*a, &b|
          unless called_by.include?([a, caller.first])
            RSpec.describe(*a, &b)
            called_by << [a, caller.first]
          end
        end
      end
      (class << top_level; self; end).class_exec(&changes)
      Module.class_exec(&changes)

      load ARGV[0]
    elsif ARGV[0] && File.directory?(ARGV[0])
      Dir["#{ARGV[0]}/**/*_test.rb"].each do |path|
        load path
      end
    else
      Dir["#{path}/**/*_test.rb"].each do |path|
        load path
      end
    end

    build_specs
  end

  def build_specs
    ObjectSpace.each_object(::Class).select do |klass|
      klass < MiniTest::Unit::TestCase
    end.each do |klass|
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

module UnitTestAssertMap
  def spec
    @spec || self # to handle the case for shoulda context.. :)
  end

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

module MiniTest
  module Unit
    class TestCase
      class << self
        def included_modules
          @included_modules ||= []
        end

        def include(a)
          included_modules << a
          super
        end
      end

      attr_writer :spec

      include UnitTestAssertMap
    end
  end
end

# shoulda-context helpers
module ShouldaForRspec
  def self.included(base)
    base.extend *ClassMethods
  end

  module ClassMethods
  end
end

RSpec.configure do |c|
  c.mock_with :mocha

  c.before(:all) do
    # should really only do this the first time rather than for each test...
    MiniTest::Unit::TestCase.included_modules.each do |mod|
      c.include(mod)
    end
  end

  c.disable_monkey_patching!
end

TestUnitLoader.new(File.join(__dir__, 'unit_test_migration'))
