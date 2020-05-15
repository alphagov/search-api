module Fixtures
  module LearnToRankExplain
    def default_explanation
      {
        "value" => 5.6723795,
        "description" => "function score, product of:",
        "details" => [
          {
            "value" => 988.3336,
            "description" => "function score, product of:",
            "details" => [
              {
                "value" => 175.70375,
                "description" => "function score, product of:",
                "details" => [
                  {
                    "value" => 204.98769,
                    "description" => "sum of:",
                    "details" => [
                      {
                        "value" => 114.29011,
                        "description" => "sum of:",
                        "details" => [
                          {
                            "value" => 57.372513,
                            "description" => "weight(title.synonym:nation in 4861) [PerFieldSimilarity], result of:",
                            "details" => [
                              {
                                "value" => 57.372513,
                                "description" => "score(doc=4861,freq=1.0 =\ntermFreq=1.0\n), product of:",
                                "details" => [
                                  {
                                    "value" => 10,
                                    "description" => "boost",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 4.6167507,
                                    "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                    "details" => [
                                      {
                                        "value" => 670,
                                        "description" => "docFreq",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 67_830,
                                        "description" => "docCount",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 1.2427033,
                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                    "details" => [
                                      {
                                        "value" => 1,
                                        "description" => "termFreq=1.0",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 1.2,
                                        "description" => "parameter k1",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 0.75,
                                        "description" => "parameter b",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 9.567669,
                                        "description" => "avgFieldLength",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 5,
                                        "description" => "fieldLength",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 56.917595,
                            "description" => "weight(title.synonym:insur in\n4861) [PerFieldSimilarity], result of:",
                            "details" => [
                              {
                                "value" => 56.917595,
                                "description" => "score(doc=4861,freq=1.0 = termFreq=1.0\n), product of:",
                                "details" => [
                                  {
                                    "value" => 10,
                                    "description" => "boost",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 4.5801435,
                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                    "details" => [
                                      {
                                        "value" => 695,
                                        "description" => "docFreq",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 67_830,
                                        "description" => "docCount",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 1.2427033,
                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                    "details" => [
                                      {
                                        "value" => 1,
                                        "description" => "termFreq=1.0",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 1.2,
                                        "description" => "parameter k1",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 0.75,
                                        "description" => "parameter b",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 9.567669,
                                        "description" => "avgFieldLength",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 5,
                                        "description" => "fieldLength",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                        ],
                      },
                      {
                        "value" => 51.04151,
                        "description" => "sum of:",
                        "details" => [
                          {
                            "value" => 23.473444,
                            "description" => "weight(description.synonym:nation in 4861) [PerFieldSimilarity], result of:",
                            "details" => [
                              {
                                "value" => 23.473444,
                                "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                "details" => [
                                  {
                                    "value" => 5,
                                    "description" => "boost",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 5.4677863,
                                    "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                    "details" => [
                                      {
                                        "value" => 115,
                                        "description" => "docFreq",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 27_365,
                                        "description" => "docCount",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 0.85860866,
                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                    "details" => [
                                      {
                                        "value" => 2,
                                        "description" => "termFreq=2.0",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 1.2,
                                        "description" => "parameter k1",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 0.75,
                                        "description" => "parameter b",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 6.6912847,
                                        "description" => "avgFieldLength",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 21,
                                        "description" => "fieldLength",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 27.568068,
                            "description" => "weight(description.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                            "details" => [
                              {
                                "value" => 27.568068,
                                "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                "details" => [
                                  {
                                    "value" => 5,
                                    "description" => "boost",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 6.4215674,
                                    "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                    "details" => [
                                      {
                                        "value" => 44,
                                        "description" => "docFreq",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 27_365,
                                        "description" => "docCount",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 0.85860866,
                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                    "details" => [
                                      {
                                        "value" => 2,
                                        "description" => "termFreq=2.0",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 1.2,
                                        "description" => "parameter k1",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 0.75,
                                        "description" => "parameter b",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 6.6912847,
                                        "description" => "avgFieldLength",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 21,
                                        "description" => "fieldLength",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                        ],
                      },
                      {
                        "value" => 22.540745,
                        "description" => "sum of:",
                        "details" => [
                          {
                            "value" => 10.288081,
                            "description" => "weight(indexable_content.synonym:nation in\n4861) [PerFieldSimilarity], result of:",
                            "details" => [
                              {
                                "value" => 10.288081,
                                "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                "details" => [
                                  {
                                    "value" => 2,
                                    "description" => "boost",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 2.4964333,
                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                    "details" => [
                                      {
                                        "value" => 5369,
                                        "description" => "docFreq",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 65_180,
                                        "description" => "docCount",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 2.060556,
                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                    "details" => [
                                      {
                                        "value" => 11,
                                        "description" => "termFreq=11.0",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 1.2,
                                        "description" => "parameter k1",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 0.75,
                                        "description" => "parameter b",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 437.44016,
                                        "description" => "avgFieldLength",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 216,
                                        "description" => "fieldLength",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 12.252665,
                            "description" => "weight(indexable_content.synonym:insur in 4861) [PerFieldSimilarity], result\nof:",
                            "details" => [
                              {
                                "value" => 12.252665,
                                "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                "details" => [
                                  {
                                    "value" => 2,
                                    "description" => "boost",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 2.9731452,
                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) / (docFreq +\n0.5)) from:",
                                    "details" => [
                                      {
                                        "value" => 3333,
                                        "description" => "docFreq",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 65_180,
                                        "description" => "docCount",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 2.060556,
                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq\n+ k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                    "details" => [
                                      {
                                        "value" => 11,
                                        "description" => "termFreq=11.0",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 1.2,
                                        "description" => "parameter k1",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 0.75,
                                        "description" => "parameter b",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 437.44016,
                                        "description" => "avgFieldLength",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 216,
                                        "description" => "fieldLength",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                        ],
                      },
                      {
                        "value" => 5.714505,
                        "description" => "max of:",
                        "details" => [
                          {
                            "value" => 5.714505,
                            "description" => "sum of:",
                            "details" => [
                              {
                                "value" => 2.8686256,
                                "description" => "weight(title.synonym:nation in 4861)\n[PerFieldSimilarity], result of:",
                                "details" => [
                                  {
                                    "value" => 2.8686256,
                                    "description" => "score(doc=4861,freq=1.0 = termFreq=1.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 4.6167507,
                                        "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 670,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 67_830,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 1.2427033,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "termFreq=1.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 9.567669,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 5,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                              {
                                "value" => 2.8458798,
                                "description" => "weight(title.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                                "details" => [
                                  {
                                    "value" => 2.8458798,
                                    "description" => "score(doc=4861,freq=1.0 =\ntermFreq=1.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 4.5801435,
                                        "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 695,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 67_830,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 1.2427033,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "termFreq=1.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 9.567669,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 5,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 5.635186,
                            "description" => "sum of:",
                            "details" => [
                              {
                                "value" => 2.5720203,
                                "description" => "weight(indexable_content.synonym:nation in\n4861) [PerFieldSimilarity], result of:",
                                "details" => [
                                  {
                                    "value" => 2.5720203,
                                    "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 2.4964333,
                                        "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 5369,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 65_180,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 2.060556,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 11,
                                            "description" => "termFreq=11.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 437.44016,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 216,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                              {
                                "value" => 3.0631661,
                                "description" => "weight(indexable_content.synonym:insur in 4861) [PerFieldSimilarity], result\nof:",
                                "details" => [
                                  {
                                    "value" => 3.0631661,
                                    "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 2.9731452,
                                        "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) / (docFreq +\n0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 3333,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 65_180,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 2.060556,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq\n+ k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 11,
                                            "description" => "termFreq=11.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 437.44016,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 216,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 5.104151,
                            "description" => "sum of:",
                            "details" => [
                              {
                                "value" => 2.3473444,
                                "description" => "weight(description.synonym:nation in 4861) [PerFieldSimilarity], result of:",
                                "details" => [
                                  {
                                    "value" => 2.3473444,
                                    "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 5.4677863,
                                        "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 115,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 27_365,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 0.85860866,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 2,
                                            "description" => "termFreq=2.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 6.6912847,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 21,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                              {
                                "value" => 2.7568066,
                                "description" => "weight(description.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                                "details" => [
                                  {
                                    "value" => 2.7568066,
                                    "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 6.4215674,
                                        "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 44,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 27_365,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 0.85860866,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 2,
                                            "description" => "termFreq=2.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 6.6912847,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 21,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                        ],
                      },
                      {
                        "value" => 5.714505,
                        "description" => "max of:",
                        "details" => [
                          {
                            "value" => 5.714505,
                            "description" => "sum of:",
                            "details" => [
                              {
                                "value" => 2.8686256,
                                "description" => "weight(title.synonym:nation in 4861) [PerFieldSimilarity],\nresult of:",
                                "details" => [
                                  {
                                    "value" => 2.8686256,
                                    "description" => "score(doc=4861,freq=1.0 = termFreq=1.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 4.6167507,
                                        "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) / (docFreq +\n0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 670,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 67_830,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 1.2427033,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "termFreq=1.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 9.567669,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 5,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                              {
                                "value" => 2.8458798,
                                "description" => "weight(title.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                                "details" => [
                                  {
                                    "value" => 2.8458798,
                                    "description" => "score(doc=4861,freq=1.0 =\ntermFreq=1.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 4.5801435,
                                        "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 695,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 67_830,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 1.2427033,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "termFreq=1.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 9.567669,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 5,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 5.635186,
                            "description" => "sum of:",
                            "details" => [
                              {
                                "value" => 2.5720203,
                                "description" => "weight(indexable_content.synonym:nation in\n4861) [PerFieldSimilarity], result of:",
                                "details" => [
                                  {
                                    "value" => 2.5720203,
                                    "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 2.4964333,
                                        "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 5369,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 65_180,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 2.060556,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 11,
                                            "description" => "termFreq=11.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 437.44016,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 216,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                              {
                                "value" => 3.0631661,
                                "description" => "weight(indexable_content.synonym:insur in 4861) [PerFieldSimilarity], result\nof:",
                                "details" => [
                                  {
                                    "value" => 3.0631661,
                                    "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 2.9731452,
                                        "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) / (docFreq +\n0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 3333,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 65_180,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 2.060556,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq\n+ k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 11,
                                            "description" => "termFreq=11.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 437.44016,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 216,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 5.104151,
                            "description" => "sum of:",
                            "details" => [
                              {
                                "value" => 2.3473444,
                                "description" => "weight(description.synonym:nation in 4861) [PerFieldSimilarity], result of:",
                                "details" => [
                                  {
                                    "value" => 2.3473444,
                                    "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 5.4677863,
                                        "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 115,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 27_365,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 0.85860866,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 2,
                                            "description" => "termFreq=2.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 6.6912847,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 21,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                              {
                                "value" => 2.7568066,
                                "description" => "weight(description.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                                "details" => [
                                  {
                                    "value" => 2.7568066,
                                    "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                    "details" => [
                                      {
                                        "value" => 0.5,
                                        "description" => "boost",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 6.4215674,
                                        "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                        "details" => [
                                          {
                                            "value" => 44,
                                            "description" => "docFreq",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 27_365,
                                            "description" => "docCount",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 0.85860866,
                                        "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                        "details" => [
                                          {
                                            "value" => 2,
                                            "description" => "termFreq=2.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.2,
                                            "description" => "parameter k1",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.75,
                                            "description" => "parameter b",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 6.6912847,
                                            "description" => "avgFieldLength",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 21,
                                            "description" => "fieldLength",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                        ],
                      },
                      {
                        "value" => 5.6863165,
                        "description" => "sum of:",
                        "details" => [
                          {
                            "value" => 2.594289,
                            "description" => "weight(all_searchable_text.synonym:nation\nin 4861) [PerFieldSimilarity], result of:",
                            "details" => [
                              {
                                "value" => 2.594289,
                                "description" => "score(doc=4861,freq=13.0 = termFreq=13.0\n), product of:",
                                "details" => [
                                  {
                                    "value" => 0.5,
                                    "description" => "boost",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 2.499161,
                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                    "details" => [
                                      {
                                        "value" => 5392,
                                        "description" => "docFreq",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 65_638,
                                        "description" => "docCount",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 2.076128,
                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                    "details" => [
                                      {
                                        "value" => 13,
                                        "description" => "termFreq=13.0",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 1.2,
                                        "description" => "parameter k1",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 0.75,
                                        "description" => "parameter b",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 438.984,
                                        "description" => "avgFieldLength",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 232,
                                        "description" => "fieldLength",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 3.0920277,
                            "description" => "weight(all_searchable_text.synonym:insur in 4861) [PerFieldSimilarity], result\nof:",
                            "details" => [
                              {
                                "value" => 3.0920277,
                                "description" => "score(doc=4861,freq=13.0 = termFreq=13.0\n), product of:",
                                "details" => [
                                  {
                                    "value" => 0.5,
                                    "description" => "boost",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 2.9786484,
                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) / (docFreq +\n0.5)) from:",
                                    "details" => [
                                      {
                                        "value" => 3338,
                                        "description" => "docFreq",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 65_638,
                                        "description" => "docCount",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 2.076128,
                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq\n+ k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                    "details" => [
                                      {
                                        "value" => 13,
                                        "description" => "termFreq=13.0",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 1.2,
                                        "description" => "parameter k1",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 0.75,
                                        "description" => "parameter b",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 438.984,
                                        "description" => "avgFieldLength",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 232,
                                        "description" => "fieldLength",
                                        "details" => [],
                                      },
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                        ],
                      },
                    ],
                  },
                  {
                    "value" => 0.8571429,
                    "description" => "min\nof:",
                    "details" => [
                      {
                        "value" => 0.8571429,
                        "description" => "function score, score\nmode [sum]",
                        "details" => [
                          {
                            "value" => 0.14285715,
                            "description" => "function score,\nproduct of:",
                            "details" => [
                              {
                                "value" => 1,
                                "description" => "match filter:\n(+title.synonym:nation +title.synonym:insur)^10.0",
                                "details" => [],
                              },
                              {
                                "value" => 0.14285715,
                                "description" => "product of:",
                                "details" => [
                                  {
                                    "value" => 1,
                                    "description" => "constant score 1.0 - no function provided",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 0.14285715,
                                    "description" => "weight",
                                    "details" => [],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 0.14285715,
                            "description" => "function score, product of:",
                            "details" => [
                              {
                                "value" => 1,
                                "description" => "match filter: (+description.synonym:nation\n+description.synonym:insur)^5.0",
                                "details" => [],
                              },
                              {
                                "value" => 0.14285715,
                                "description" => "product of:",
                                "details" => [
                                  {
                                    "value" => 1,
                                    "description" => "constant score 1.0 - no function provided",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 0.14285715,
                                    "description" => "weight",
                                    "details" => [],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 0.14285715,
                            "description" => "function score, product of:",
                            "details" => [
                              {
                                "value" => 1,
                                "description" => "match filter: (+indexable_content.synonym:nation\n+indexable_content.synonym:insur)^2.0",
                                "details" => [],
                              },
                              {
                                "value" => 0.14285715,
                                "description" => "product of:",
                                "details" => [
                                  {
                                    "value" => 1,
                                    "description" => "constant score 1.0 - no function provided",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 0.14285715,
                                    "description" => "weight",
                                    "details" => [],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 0.14285715,
                            "description" => "function score, product of:",
                            "details" => [
                              {
                                "value" => 1,
                                "description" => "match filter: (((+title.synonym:nation\n+title.synonym:insur) | (+indexable_content.synonym:nation\n+indexable_content.synonym:insur) | (+acronym.synonym:nation\n+acronym.synonym:insur) | (+description.synonym:nation\n+description.synonym:insur)))^0.5",
                                "details" => [],
                              },
                              {
                                "value" => 0.14285715,
                                "description" => "product of:",
                                "details" => [
                                  {
                                    "value" => 1,
                                    "description" => "constant score 1.0 - no function provided",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 0.14285715,
                                    "description" => "weight",
                                    "details" => [],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 0.14285715,
                            "description" => "function score, product of:",
                            "details" => [
                              {
                                "value" => 1,
                                "description" => "match filter: (((title.synonym:nation\ntitle.synonym:insur) | (indexable_content.synonym:nation\nindexable_content.synonym:insur) | (acronym.synonym:nation\nacronym.synonym:insur) | (description.synonym:nation\ndescription.synonym:insur)))^0.5",
                                "details" => [],
                              },
                              {
                                "value" => 0.14285715,
                                "description" => "product of:",
                                "details" => [
                                  {
                                    "value" => 1,
                                    "description" => "constant score 1.0 - no function provided",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 0.14285715,
                                    "description" => "weight",
                                    "details" => [],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 0.14285715,
                            "description" => "function score, product of:",
                            "details" => [
                              {
                                "value" => 1,
                                "description" => "match filter: ((all_searchable_text.synonym:nation\nall_searchable_text.synonym:insur)~2)^0.5",
                                "details" => [],
                              },
                              {
                                "value" => 0.14285715,
                                "description" => "product of:",
                                "details" => [
                                  {
                                    "value" => 1,
                                    "description" => "constant score 1.0 - no function provided",
                                    "details" => [],
                                  },
                                  {
                                    "value" => 0.14285715,
                                    "description" => "weight",
                                    "details" => [],
                                  },
                                ],
                              },
                            ],
                          },
                        ],
                      },
                      {
                        "value" => 3.4028235e+38,
                        "description" => "maxBoost",
                        "details" => [],
                      },
                    ],
                  },
                ],
              },
              {
                "value" => 5.625,
                "description" => "min of:",
                "details" => [
                  {
                    "value" => 5.625,
                    "description" => "function score, score mode [multiply]",
                    "details" => [
                      {
                        "value" => 1.5,
                        "description" => "function score, product of:",
                        "details" => [
                          {
                            "value" => 1,
                            "description" => "match filter: format:transaction",
                            "details" => [],
                          },
                          {
                            "value" => 1.5,
                            "description" => "product of:",
                            "details" => [
                              {
                                "value" => 1,
                                "description" => "constant score 1.0 - no function provided",
                                "details" => [],
                              },
                              {
                                "value" => 1.5,
                                "description" => "weight",
                                "details" => [],
                              },
                            ],
                          },
                        ],
                      },
                      {
                        "value" => 2.5,
                        "description" => "function score, product of:",
                        "details" => [
                          {
                            "value" => 1,
                            "description" => "match\nfilter: navigation_document_supertype:guidance",
                            "details" => [],
                          },
                          {
                            "value" => 2.5,
                            "description" => "product of:",
                            "details" => [
                              {
                                "value" => 1,
                                "description" => "constant score 1.0 - no function provided",
                                "details" => [],
                              },
                              {
                                "value" => 2.5,
                                "description" => "weight",
                                "details" => [],
                              },
                            ],
                          },
                        ],
                      },
                      {
                        "value" => 1.5,
                        "description" => "function score, product of:",
                        "details" => [
                          {
                            "value" => 1,
                            "description" => "match\nfilter: search_user_need_document_supertype:core",
                            "details" => [],
                          },
                          {
                            "value" => 1.5,
                            "description" => "product of:",
                            "details" => [
                              {
                                "value" => 1,
                                "description" => "constant score 1.0 - no function provided",
                                "details" => [],
                              },
                              {
                                "value" => 1.5,
                                "description" => "weight",
                                "details" => [],
                              },
                            ],
                          },
                        ],
                      },
                    ],
                  },
                  {
                    "value" => 3.4028235e+38,
                    "description" => "maxBoost",
                    "details" => [],
                  },
                ],
              },
            ],
          },
          {
            "value" => 0.005739337,
            "description" => "min of:",
            "details" => [
              {
                "value" => 0.005739337,
                "description" => "script score function, computed with script:\"Script{type=source,\nlang='painless', idOrCode='doc['popularity'].value + 0.001', options={},\nparams={}}\" and parameters: \n{}",
                "details" => [
                  {
                    "value" => 988.3336,
                    "description" => "_score: ",
                    "details" => [
                      {
                        "value" => 988.3336,
                        "description" => "function score, product of:",
                        "details" => [
                          {
                            "value" => 175.70375,
                            "description" => "function score, product of:",
                            "details" => [
                              {
                                "value" => 204.98769,
                                "description" => "sum of:",
                                "details" => [
                                  {
                                    "value" => 114.29011,
                                    "description" => "sum of:",
                                    "details" => [
                                      {
                                        "value" => 57.372513,
                                        "description" => "weight(title.synonym:nation\nin 4861) [PerFieldSimilarity], result of:",
                                        "details" => [
                                          {
                                            "value" => 57.372513,
                                            "description" => "score(doc=4861,freq=1.0 = termFreq=1.0\n), product of:",
                                            "details" => [
                                              {
                                                "value" => 10,
                                                "description" => "boost",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 4.6167507,
                                                "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 670,
                                                    "description" => "docFreq",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 67_830,
                                                    "description" => "docCount",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                              {
                                                "value" => 1.2427033,
                                                "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 1,
                                                    "description" => "termFreq=1.0",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 1.2,
                                                    "description" => "parameter k1",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 0.75,
                                                    "description" => "parameter b",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 9.567669,
                                                    "description" => "avgFieldLength",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 5,
                                                    "description" => "fieldLength",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 56.917595,
                                        "description" => "weight(title.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                                        "details" => [
                                          {
                                            "value" => 56.917595,
                                            "description" => "score(doc=4861,freq=1.0 =\ntermFreq=1.0\n), product of:",
                                            "details" => [
                                              {
                                                "value" => 10,
                                                "description" => "boost",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 4.5801435,
                                                "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 695,
                                                    "description" => "docFreq",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 67_830,
                                                    "description" => "docCount",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                              {
                                                "value" => 1.2427033,
                                                "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 1,
                                                    "description" => "termFreq=1.0",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 1.2,
                                                    "description" => "parameter k1",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 0.75,
                                                    "description" => "parameter b",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 9.567669,
                                                    "description" => "avgFieldLength",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 5,
                                                    "description" => "fieldLength",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 51.04151,
                                    "description" => "sum of:",
                                    "details" => [
                                      {
                                        "value" => 23.473444,
                                        "description" => "weight(description.synonym:nation in 4861)\n[PerFieldSimilarity], result of:",
                                        "details" => [
                                          {
                                            "value" => 23.473444,
                                            "description" => "score(doc=4861,freq=2.0 = termFreq=2.0\n), product of:",
                                            "details" => [
                                              {
                                                "value" => 5,
                                                "description" => "boost",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 5.4677863,
                                                "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 115,
                                                    "description" => "docFreq",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 27_365,
                                                    "description" => "docCount",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                              {
                                                "value" => 0.85860866,
                                                "description" => "tfNorm, computed as (freq * (k1 + 1))\n/ (freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 2,
                                                    "description" => "termFreq=2.0",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 1.2,
                                                    "description" => "parameter k1",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 0.75,
                                                    "description" => "parameter b",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 6.6912847,
                                                    "description" => "avgFieldLength",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 21,
                                                    "description" => "fieldLength",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 27.568068,
                                        "description" => "weight(description.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                                        "details" => [
                                          {
                                            "value" => 27.568068,
                                            "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                            "details" => [
                                              {
                                                "value" => 5,
                                                "description" => "boost",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 6.4215674,
                                                "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 44,
                                                    "description" => "docFreq",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 27_365,
                                                    "description" => "docCount",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                              {
                                                "value" => 0.85860866,
                                                "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 2,
                                                    "description" => "termFreq=2.0",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 1.2,
                                                    "description" => "parameter k1",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 0.75,
                                                    "description" => "parameter b",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 6.6912847,
                                                    "description" => "avgFieldLength",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 21,
                                                    "description" => "fieldLength",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 22.540745,
                                    "description" => "sum of:",
                                    "details" => [
                                      {
                                        "value" => 10.288081,
                                        "description" => "weight(indexable_content.synonym:nation in\n4861) [PerFieldSimilarity], result of:",
                                        "details" => [
                                          {
                                            "value" => 10.288081,
                                            "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                            "details" => [
                                              {
                                                "value" => 2,
                                                "description" => "boost",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 2.4964333,
                                                "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 5369,
                                                    "description" => "docFreq",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 65_180,
                                                    "description" => "docCount",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                              {
                                                "value" => 2.060556,
                                                "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 11,
                                                    "description" => "termFreq=11.0",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 1.2,
                                                    "description" => "parameter k1",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 0.75,
                                                    "description" => "parameter b",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 437.44016,
                                                    "description" => "avgFieldLength",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 216,
                                                    "description" => "fieldLength",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 12.252665,
                                        "description" => "weight(indexable_content.synonym:insur in 4861) [PerFieldSimilarity], result\nof:",
                                        "details" => [
                                          {
                                            "value" => 12.252665,
                                            "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                            "details" => [
                                              {
                                                "value" => 2,
                                                "description" => "boost",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 2.9731452,
                                                "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) / (docFreq +\n0.5)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 3333,
                                                    "description" => "docFreq",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 65_180,
                                                    "description" => "docCount",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                              {
                                                "value" => 2.060556,
                                                "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq\n+ k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 11,
                                                    "description" => "termFreq=11.0",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 1.2,
                                                    "description" => "parameter k1",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 0.75,
                                                    "description" => "parameter b",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 437.44016,
                                                    "description" => "avgFieldLength",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 216,
                                                    "description" => "fieldLength",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 5.714505,
                                    "description" => "max of:",
                                    "details" => [
                                      {
                                        "value" => 5.714505,
                                        "description" => "sum of:",
                                        "details" => [
                                          {
                                            "value" => 2.8686256,
                                            "description" => "weight(title.synonym:nation in 4861)\n[PerFieldSimilarity], result of:",
                                            "details" => [
                                              {
                                                "value" => 2.8686256,
                                                "description" => "score(doc=4861,freq=1.0 = termFreq=1.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 4.6167507,
                                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 670,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 67_830,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 1.2427033,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 1,
                                                        "description" => "termFreq=1.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 9.567669,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 5,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                          {
                                            "value" => 2.8458798,
                                            "description" => "weight(title.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                                            "details" => [
                                              {
                                                "value" => 2.8458798,
                                                "description" => "score(doc=4861,freq=1.0 =\ntermFreq=1.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 4.5801435,
                                                    "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 695,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 67_830,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 1.2427033,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 1,
                                                        "description" => "termFreq=1.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 9.567669,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 5,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 5.635186,
                                        "description" => "sum of:",
                                        "details" => [
                                          {
                                            "value" => 2.5720203,
                                            "description" => "weight(indexable_content.synonym:nation in\n4861) [PerFieldSimilarity], result of:",
                                            "details" => [
                                              {
                                                "value" => 2.5720203,
                                                "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 2.4964333,
                                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 5369,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 65_180,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 2.060556,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 11,
                                                        "description" => "termFreq=11.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 437.44016,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 216,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                          {
                                            "value" => 3.0631661,
                                            "description" => "weight(indexable_content.synonym:insur in 4861) [PerFieldSimilarity], result\nof:",
                                            "details" => [
                                              {
                                                "value" => 3.0631661,
                                                "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 2.9731452,
                                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) / (docFreq +\n0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 3333,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 65_180,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 2.060556,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq\n+ k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 11,
                                                        "description" => "termFreq=11.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 437.44016,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 216,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 5.104151,
                                        "description" => "sum of:",
                                        "details" => [
                                          {
                                            "value" => 2.3473444,
                                            "description" => "weight(description.synonym:nation in 4861) [PerFieldSimilarity], result of:",
                                            "details" => [
                                              {
                                                "value" => 2.3473444,
                                                "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 5.4677863,
                                                    "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 115,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 27_365,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 0.85860866,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 2,
                                                        "description" => "termFreq=2.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 6.6912847,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 21,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                          {
                                            "value" => 2.7568066,
                                            "description" => "weight(description.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                                            "details" => [
                                              {
                                                "value" => 2.7568066,
                                                "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 6.4215674,
                                                    "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 44,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 27_365,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 0.85860866,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 2,
                                                        "description" => "termFreq=2.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 6.6912847,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 21,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 5.714505,
                                    "description" => "max of:",
                                    "details" => [
                                      {
                                        "value" => 5.714505,
                                        "description" => "sum of:",
                                        "details" => [
                                          {
                                            "value" => 2.8686256,
                                            "description" => "weight(title.synonym:nation in 4861) [PerFieldSimilarity],\nresult of:",
                                            "details" => [
                                              {
                                                "value" => 2.8686256,
                                                "description" => "score(doc=4861,freq=1.0 = termFreq=1.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 4.6167507,
                                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) / (docFreq +\n0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 670,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 67_830,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 1.2427033,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 1,
                                                        "description" => "termFreq=1.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 9.567669,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 5,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                          {
                                            "value" => 2.8458798,
                                            "description" => "weight(title.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                                            "details" => [
                                              {
                                                "value" => 2.8458798,
                                                "description" => "score(doc=4861,freq=1.0 =\ntermFreq=1.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 4.5801435,
                                                    "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 695,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 67_830,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 1.2427033,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 1,
                                                        "description" => "termFreq=1.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 9.567669,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 5,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 5.635186,
                                        "description" => "sum of:",
                                        "details" => [
                                          {
                                            "value" => 2.5720203,
                                            "description" => "weight(indexable_content.synonym:nation in\n4861) [PerFieldSimilarity], result of:",
                                            "details" => [
                                              {
                                                "value" => 2.5720203,
                                                "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 2.4964333,
                                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 5369,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 65_180,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 2.060556,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 11,
                                                        "description" => "termFreq=11.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 437.44016,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 216,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                          {
                                            "value" => 3.0631661,
                                            "description" => "weight(indexable_content.synonym:insur in 4861) [PerFieldSimilarity], result\nof:",
                                            "details" => [
                                              {
                                                "value" => 3.0631661,
                                                "description" => "score(doc=4861,freq=11.0 = termFreq=11.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 2.9731452,
                                                    "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) / (docFreq +\n0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 3333,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 65_180,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 2.060556,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq\n+ k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 11,
                                                        "description" => "termFreq=11.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 437.44016,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 216,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 5.104151,
                                        "description" => "sum of:",
                                        "details" => [
                                          {
                                            "value" => 2.3473444,
                                            "description" => "weight(description.synonym:nation in 4861) [PerFieldSimilarity], result of:",
                                            "details" => [
                                              {
                                                "value" => 2.3473444,
                                                "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 5.4677863,
                                                    "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 115,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 27_365,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 0.85860866,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 2,
                                                        "description" => "termFreq=2.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 6.6912847,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 21,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                          {
                                            "value" => 2.7568066,
                                            "description" => "weight(description.synonym:insur in 4861) [PerFieldSimilarity], result of:",
                                            "details" => [
                                              {
                                                "value" => 2.7568066,
                                                "description" => "score(doc=4861,freq=2.0 =\ntermFreq=2.0\n), product of:",
                                                "details" => [
                                                  {
                                                    "value" => 0.5,
                                                    "description" => "boost",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 6.4215674,
                                                    "description" => "idf, computed as\nlog(1 + (docCount - docFreq + 0.5) / (docFreq + 0.5)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 44,
                                                        "description" => "docFreq",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 27_365,
                                                        "description" => "docCount",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                  {
                                                    "value" => 0.85860866,
                                                    "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq + k1 * (1 - b + b\n* fieldLength / avgFieldLength)) from:",
                                                    "details" => [
                                                      {
                                                        "value" => 2,
                                                        "description" => "termFreq=2.0",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 1.2,
                                                        "description" => "parameter k1",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 0.75,
                                                        "description" => "parameter b",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 6.6912847,
                                                        "description" => "avgFieldLength",
                                                        "details" => [],
                                                      },
                                                      {
                                                        "value" => 21,
                                                        "description" => "fieldLength",
                                                        "details" => [],
                                                      },
                                                    ],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 5.6863165,
                                    "description" => "sum of:",
                                    "details" => [
                                      {
                                        "value" => 2.594289,
                                        "description" => "weight(all_searchable_text.synonym:nation\nin 4861) [PerFieldSimilarity], result of:",
                                        "details" => [
                                          {
                                            "value" => 2.594289,
                                            "description" => "score(doc=4861,freq=13.0 = termFreq=13.0\n), product of:",
                                            "details" => [
                                              {
                                                "value" => 0.5,
                                                "description" => "boost",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 2.499161,
                                                "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) /\n(docFreq + 0.5)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 5392,
                                                    "description" => "docFreq",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 65_638,
                                                    "description" => "docCount",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                              {
                                                "value" => 2.076128,
                                                "description" => "tfNorm, computed as (freq * (k1 + 1)) /\n(freq + k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 13,
                                                    "description" => "termFreq=13.0",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 1.2,
                                                    "description" => "parameter k1",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 0.75,
                                                    "description" => "parameter b",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 438.984,
                                                    "description" => "avgFieldLength",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 232,
                                                    "description" => "fieldLength",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 3.0920277,
                                        "description" => "weight(all_searchable_text.synonym:insur in 4861) [PerFieldSimilarity], result\nof:",
                                        "details" => [
                                          {
                                            "value" => 3.0920277,
                                            "description" => "score(doc=4861,freq=13.0 = termFreq=13.0\n), product of:",
                                            "details" => [
                                              {
                                                "value" => 0.5,
                                                "description" => "boost",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 2.9786484,
                                                "description" => "idf, computed as log(1 + (docCount - docFreq + 0.5) / (docFreq +\n0.5)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 3338,
                                                    "description" => "docFreq",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 65_638,
                                                    "description" => "docCount",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                              {
                                                "value" => 2.076128,
                                                "description" => "tfNorm, computed as (freq * (k1 + 1)) / (freq\n+ k1 * (1 - b + b * fieldLength / avgFieldLength)) from:",
                                                "details" => [
                                                  {
                                                    "value" => 13,
                                                    "description" => "termFreq=13.0",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 1.2,
                                                    "description" => "parameter k1",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 0.75,
                                                    "description" => "parameter b",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 438.984,
                                                    "description" => "avgFieldLength",
                                                    "details" => [],
                                                  },
                                                  {
                                                    "value" => 232,
                                                    "description" => "fieldLength",
                                                    "details" => [],
                                                  },
                                                ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                              {
                                "value" => 0.8571429,
                                "description" => "min\nof:",
                                "details" => [
                                  {
                                    "value" => 0.8571429,
                                    "description" => "function score, score\nmode [sum]",
                                    "details" => [
                                      {
                                        "value" => 0.14285715,
                                        "description" => "function score,\nproduct of:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "match filter:\n(+title.synonym:nation +title.synonym:insur)^10.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.14285715,
                                            "description" => "product of:",
                                            "details" => [
                                              {
                                                "value" => 1,
                                                "description" => "constant score 1.0 - no function provided",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 0.14285715,
                                                "description" => "weight",
                                                "details" => [],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 0.14285715,
                                        "description" => "function score, product of:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "match filter: (+description.synonym:nation\n+description.synonym:insur)^5.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.14285715,
                                            "description" => "product of:",
                                            "details" => [
                                              {
                                                "value" => 1,
                                                "description" => "constant score 1.0 - no function provided",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 0.14285715,
                                                "description" => "weight",
                                                "details" => [],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 0.14285715,
                                        "description" => "function score, product of:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "match filter: (+indexable_content.synonym:nation\n+indexable_content.synonym:insur)^2.0",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.14285715,
                                            "description" => "product of:",
                                            "details" => [
                                              {
                                                "value" => 1,
                                                "description" => "constant score 1.0 - no function provided",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 0.14285715,
                                                "description" => "weight",
                                                "details" => [],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 0.14285715,
                                        "description" => "function score, product of:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "match filter: (((+title.synonym:nation\n+title.synonym:insur) | (+indexable_content.synonym:nation\n+indexable_content.synonym:insur) | (+acronym.synonym:nation\n+acronym.synonym:insur) | (+description.synonym:nation\n+description.synonym:insur)))^0.5",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.14285715,
                                            "description" => "product of:",
                                            "details" => [
                                              {
                                                "value" => 1,
                                                "description" => "constant score 1.0 - no function provided",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 0.14285715,
                                                "description" => "weight",
                                                "details" => [],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 0.14285715,
                                        "description" => "function score, product of:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "match filter: (((title.synonym:nation\ntitle.synonym:insur) | (indexable_content.synonym:nation\nindexable_content.synonym:insur) | (acronym.synonym:nation\nacronym.synonym:insur) | (description.synonym:nation\ndescription.synonym:insur)))^0.5",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.14285715,
                                            "description" => "product of:",
                                            "details" => [
                                              {
                                                "value" => 1,
                                                "description" => "constant score 1.0 - no function provided",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 0.14285715,
                                                "description" => "weight",
                                                "details" => [],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      {
                                        "value" => 0.14285715,
                                        "description" => "function score, product of:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "match filter: ((all_searchable_text.synonym:nation\nall_searchable_text.synonym:insur)~2)^0.5",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 0.14285715,
                                            "description" => "product of:",
                                            "details" => [
                                              {
                                                "value" => 1,
                                                "description" => "constant score 1.0 - no function provided",
                                                "details" => [],
                                              },
                                              {
                                                "value" => 0.14285715,
                                                "description" => "weight",
                                                "details" => [],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 3.4028235e+38,
                                    "description" => "maxBoost",
                                    "details" => [],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            "value" => 5.625,
                            "description" => "min of:",
                            "details" => [
                              {
                                "value" => 5.625,
                                "description" => "function score, score mode [multiply]",
                                "details" => [
                                  {
                                    "value" => 1.5,
                                    "description" => "function score, product of:",
                                    "details" => [
                                      {
                                        "value" => 1,
                                        "description" => "match filter: format:transaction",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 1.5,
                                        "description" => "product of:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "constant score 1.0 - no function provided",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.5,
                                            "description" => "weight",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 2.5,
                                    "description" => "function score, product of:",
                                    "details" => [
                                      {
                                        "value" => 1,
                                        "description" => "match\nfilter: navigation_document_supertype:guidance",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 2.5,
                                        "description" => "product of:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "constant score 1.0 - no function provided",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 2.5,
                                            "description" => "weight",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                  {
                                    "value" => 1.5,
                                    "description" => "function score, product of:",
                                    "details" => [
                                      {
                                        "value" => 1,
                                        "description" => "match\nfilter: search_user_need_document_supertype:core",
                                        "details" => [],
                                      },
                                      {
                                        "value" => 1.5,
                                        "description" => "product of:",
                                        "details" => [
                                          {
                                            "value" => 1,
                                            "description" => "constant score 1.0 - no function provided",
                                            "details" => [],
                                          },
                                          {
                                            "value" => 1.5,
                                            "description" => "weight",
                                            "details" => [],
                                          },
                                        ],
                                      },
                                    ],
                                  },
                                ],
                              },
                              {
                                "value" => 3.4028235e+38,
                                "description" => "maxBoost",
                                "details" => [],
                              },
                            ],
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
              {
                "value" => 3.4028235e+38,
                "description" => "maxBoost",
                "details" => [],
              },
            ],
          },
        ],
      }
    end
  end
end
