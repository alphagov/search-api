require "spec_helper"

RSpec.describe Collectors::ElasticsearchPrometheusCollector do
  it "returns a disk space gauge of the form {{node: String} => float}" do
    disk_space_gauge, = Collectors::ElasticsearchPrometheusCollector.new.metrics
    expect(disk_space_gauge.to_h.keys).to all(match(node: a_kind_of(String)))
    expect(disk_space_gauge.to_h.values).to all(be_a(Float))
  end
  it "returns a status_gauge gauge of the form {{} => integer}" do
    _, status_gauge = Collectors::ElasticsearchPrometheusCollector.new.metrics
    expect(status_gauge.to_h.keys).to all(eq({}))
    expect(status_gauge.to_h.values).to all(be_a(Integer))
  end
end
