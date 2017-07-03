require_relative 'app'

search_config = SearchConfig.new
client = Services.elasticsearch(
        hosts: search_config.elasticsearch["base_uri"],
        timeout: 30.0
      )

start = Time.now
p = nil
cc = 0
c = 0
m = 0
ScrollEnumerator.new(
        client: client,
        index_names: 'government',
        search_body: { query: { match_all: {} }, sort: [{'public_timestamp' => {order: 'asc'}}] },
        batch_size: 50,
      ) do |document|
        document
      end.each do |d|
        cc += 1
        if p
          if p['_source']['public_timestamp'] && d['_source']['public_timestamp']
            c += 1 if p['_source']['public_timestamp'] > d['_source']['public_timestamp']
          else
            m += 1
          end
        end
        p = d
      end
puts "With sort: #{Time.now - start} unordered: #{c}/#{cc} missing: #{m}"


start = Time.now
p = nil
c = 0
m = 0
ScrollEnumerator.new(
        client: client,
        index_names: 'government',
        search_body: { query: { match_all: {} } },
        batch_size: 50
      ) do |document|
        document
      end.each do |d|
        if p
          if p['_source']['public_timestamp'] && d['_source']['public_timestamp']
            c += 1 if p['_source']['public_timestamp'] > d['_source']['public_timestamp']
          else
            m += 1
          end
        end
        p = d
      end
puts "Without sort: #{Time.now - start} unordered: #{c} missing: #{m}"
