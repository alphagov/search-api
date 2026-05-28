FactoryBot.define do
  factory :document, class: Hash do
    title { "" }
    link { "/" }
    description { "" }
    indexable_content {}
    format { "answer" }
    document_type { "edition" }
    sequence :public_timestamp do |n|
      (Time.new(2000, 1, 1) + n).utc.strftime("%Y-%m-%dT%H:%M:%S")
    end
    initialize_with { attributes }
  end

  trait :cma_case do
    format { "cma_case" }
    document_type { "cma_case" }
  end

  trait :with_content do
    indexable_content { Faker::Lorem.paragraph }
  end

  trait :with_title do
    title { Faker::Book.title }
  end

  trait :with_link do
    link { "/#{Faker::Internet.slug}" }
  end

  trait :with_description do
    description { Faker::Lorem.sentence }
  end

  trait :all do
    with_content
    with_title
    with_link
    with_description
  end
end
