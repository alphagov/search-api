module Fixtures
  module DefaultMappings
    def default_mappings
      {
        "edition" => {
          "_all" => { "enabled" => true} ,
          "properties" => {
            "title" => { "type" => "string", "index" => "analyzed" },
            "description" => { "type" => "string", "index" => "analyzed" },
            "format" => { "type" => "string", "index" => "not_analyzed", "include_in_all" => false },
            "link" => { "type" => "string", "index" => "not_analyzed", "include_in_all" => false },
            "indexable_content" => { "type" => "string", "index" => "analyzed"}
          }
        },
        "best_bet" => {
          "properties" => {
            "query" => { "type" => "string", "index" => "not_analyzed" }
          }
        }
      }
    end

    def page_traffic_mappings
      {
        "page-traffic" => {
          "_all" => { "enabled" => false },
          "dynamic_templates" => [
            {
              "view_count" => {
                "match" => "vc_*",
                "mapping" => { "type" => "long", "stored" => true }
              }
            },
            {
              "view_fraction" => {
                "match" => "vf_*",
                "mapping" => { "type" => "float", "stored" => true }
              }
            },
            {
              "rank" => {
                "match" => "rank_*",
                "mapping" => { "type" => "float", "stored" => true }
              }
            }
          ],
          "properties" => {
            "path_components" => { "type" => "string", "index" => "not_analyzed" }
          }
        }
      }
    end
  end
end
