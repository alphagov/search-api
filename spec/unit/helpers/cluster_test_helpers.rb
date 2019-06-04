require 'spec_helper'

module ClusterTestHelpers
  def valid_cluster_keys
    @valid_cluster_keys ||= Clusters.cluster_keys
  end

  def invalid_cluster_keys
    @invalid_cluster_keys ||= [nil, '', 'C', :A, 'a']
  end

  def default_key
    @default_key ||= 'A'
  end
end
