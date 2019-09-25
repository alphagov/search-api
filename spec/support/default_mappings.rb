module Fixtures
  module DefaultMappings
    def default_mappings
      {
        "generic-document" => {
          "properties" => {
            "title" => { "type" => "text", "index" => true },
            "description" => { "type" => "text", "index" => true },
            "format" => { "type" => "keyword", "index" => true },
            "link" => { "type" => "keyword", "index" => true },
            "indexable_content" => { "type" => "text", "index" => true },
            "mainstream_browse_pages" => { "type" => "keyword", "index" => true },
          },
        },
      }
    end

    def page_traffic_mappings
      {
        "page-traffic" => {
          "dynamic_templates" => [
            {
              "view_count" => {
                "match" => "vc_*",
                "mapping" => { "type" => "long", "stored" => true },
              },
            },
            {
              "view_fraction" => {
                "match" => "vf_*",
                "mapping" => { "type" => "float", "stored" => true },
              },
            },
            {
              "rank" => {
                "match" => "rank_*",
                "mapping" => { "type" => "float", "stored" => true },
              },
            }
          ],
          "properties" => {
            "path_components" => { "type" => "keyword", "index" => true },
          },
        },
      }
    end
  end
end
