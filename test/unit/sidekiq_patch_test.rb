require "test_helper"

# Require a worker class, which will trigger the Sidekiq patching, just as
# loading it from the app will
require "elasticsearch/bulk_index_worker"

# This previously required "yajl/json_gem", which overwrote the JSON.generate
# method with one that didn't support the `ascii_only` flag.
require "app"

class SidekiqPatchTest < MiniTest::Unit::TestCase
  def test_dumps_ascii_only
    test_message = { message: "\u2018Get to da choppa!\u2019" }
    assert_equal(
      '{"message":"\u2018Get to da choppa!\u2019"}',
      Sidekiq.dump_json(test_message)
    )
  end
end
