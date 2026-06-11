require "spec_helper"

RSpec.describe "ErrorHandlingTest" do
  RSpec.shared_examples "a sinatra error handler" do |exception_class:, status:, body:|
    it "returns #{status} for #{exception_class}" do
      allow(SearchConfig).to receive(:run_search)
                               .and_raise(exception_class.new("error"))

      get "/search"

      expect(last_response.status).to eq(status)

      if body.respond_to?(:call)
        expect(last_response.body).to eq(body.call("error"))
      else
        expect(last_response.body).to eq(body)
      end
    end
  end

  include_examples(
    "a sinatra error handler",
    exception_class: Index::ResponseValidator::NotFound,
    status: 404,
    body: ->(msg) { msg },
  )

  include_examples(
    "a sinatra error handler",
    exception_class: Elasticsearch::Transport::Transport::Errors::RequestTimeout,
    status: 503,
    body: "Elasticsearch timed out",
  )

  include_examples(
    "a sinatra error handler",
    exception_class: Elasticsearch::Transport::Transport::SnifferTimeoutError,
    status: 503,
    body: "Elasticsearch timed out",
  )

  include_examples(
    "a sinatra error handler",
    exception_class: RedisClient::TimeoutError,
    status: 503,
    body: "Redis queue timed out",
  )

  include_examples(
    "a sinatra error handler",
    exception_class: Elasticsearch::Transport::Transport::Errors::BadRequest,
    status: 400,
    body: ->(msg) { msg },
  )

  it "notifies GovukError with the exception and params" do
    error = Index::ResponseValidator::ElasticsearchError.new("error")

    expect(GovukError).to receive(:notify).with(
      error,
      extra: hash_including(:params),
    )

    allow(SearchConfig).to receive(:run_search).and_raise(error)

    get "/search", foo: "bar"

    expect(last_response.status).to eq(500)
  end
end
