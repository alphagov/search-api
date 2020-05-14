module Search
  class AggregateResultPresenter
    attr_reader :aggregates, :search_params, :registries

    def initialize(aggregates, search_params, registries)
      @aggregates = aggregates
      @search_params = search_params
      @registries = registries
    end

    def presented_aggregates
      return {} if aggregates.nil?

      result = {}
      aggregates.each do |field, aggregate_info|
        next if field =~ /_with_missing_value$/

        aggregate_parameters = search_params.aggregates[field]

        options = aggregate_info["filtered_aggregations"]["buckets"]
        result[field] = {
          options: aggregate_options(field, options, aggregate_parameters),
          documents_with_no_value: aggregates["#{field}_with_missing_value"]["filtered_aggregations"]["doc_count"],
          total_options: options.length,
          missing_options: [options.length - aggregate_parameters[:requested], 0].max,
          scope: aggregate_parameters[:scope],
        }
      end

      result
    end

    # This is a class method, called on the output of
    # AggregateResultPresenter.new(...).presented_aggregates.  This is
    # so the examples fetched (in ../query.rb) can be derived from the
    # presented aggregates.  The alternative is conservatively
    # fetching any example which could possibly be needed, and
    # throwing away unnecessary ones after-the-fact.
    #
    # This method mutates the 'presented_aggregates' parameter.
    def self.merge_examples(presented_aggregates, examples)
      presented_aggregates.each do |field, aggregate|
        field_examples = examples[field]
        unless field_examples.nil?
          aggregate[:options].each do |option|
            option[:value]["example_info"] = field_examples.fetch(option[:value]["slug"], [])
          end
        end
      end
    end

  private

    # Get the aggregate options, sorted according to the "order" option.
    #
    # Returns the requested number of options, but will additionally return any
    # options which are part of a filter.
    def aggregate_options(field, calculated_options, aggregate_parameters)
      applied_options = filter_values_for_field(field)

      all_options = calculated_options.map { |option|
        [option["key"], option["doc_count"]]
      } + applied_options.map do |term|
        [term, 0]
      end

      unique_options = all_options.uniq do |term, _count|
        term
      end

      option_objects = unique_options.map do |term, count|
        make_aggregate_option(
          field,
          term,
          count,
          applied_options.include?(term),
          aggregate_parameters[:order],
        )
      end

      top_aggregate_options(option_objects, aggregate_parameters[:requested])
    end

    def filter_values_for_field(field)
      filter = search_params.filters.find { |applied_filter| applied_filter.field_name == field }
      filter ? filter.values : []
    end

    def make_aggregate_option(field, term, count, applied, orderings)
      AggregateOption.new(
        aggregate_option_fields(field, term),
        count,
        applied,
        orderings,
      )
    end

    def aggregate_option_fields(field, slug)
      result = field_presenter.expand(field, slug)
      unless result.is_a?(Hash)
        result = { "slug" => result }
      end

      result
    end

    # Pick the top aggregate options, but include all applied aggregate options.
    #
    # Also, when picking the top aggregate options, don't count aggregate options which
    # have a count of 0 documents (these happen when a filter is applied, but the
    # filter doesn't match any documents for the current query).  This means that
    # if a load of filters are applied, and the query is then changed while
    # keeping the filters such that the filters match no documents, then the old
    # filters are still returned in the response (so get shown in the UI such
    # that the user can remove them), but a new set of filters are also suggested
    # which might actually be useful.
    def top_aggregate_options(options, requested_count)
      suggested_options = options.sort.select { |option|
        option.count.positive?
      }.take(requested_count)
      applied_options = options.select(&:applied)
      suggested_options.concat(applied_options).uniq.sort.map(&:as_hash)
    end

    def field_presenter
      @field_presenter ||= FieldPresenter.new(registries)
    end
  end
end
