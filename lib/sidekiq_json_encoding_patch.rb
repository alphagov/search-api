require "sidekiq"

module Sidekiq
  # Sidekiq, by default, lets the JSON library decide how to encode objects,
  # including how to encode non-ASCII strings. This causes encoding problems
  # if the client is dumping jobs as UTF-8 (which it will do with UTF-8 strings
  # by default) and the worker is trying to load them as ASCII (which it does
  # by default when reading from a socket). We can get around this problem
  # entirely by forcing ASCII-only encoding (using "\uxxxx" escape sequences).
  def self.dump_json(object)
    JSON.generate(object, ascii_only: true)
  end
end
