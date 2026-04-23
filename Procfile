web: bundle exec unicorn -c ./config/unicorn.rb -p ${PORT:-3233}
worker: bundle exec sidekiq -C ./config/sidekiq.yml
govuk-index-queue-listener: bundle exec rake message_queue:insert_data_into_govuk
bulk-reindex-queue-listener: bundle exec rake message_queue:bulk_insert_data_into_govuk
