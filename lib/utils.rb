def boost_documents(documents, boosts)
  documents.each do |doc|
    if boosts.keys.include?(doc.link)
      boost = boosts[doc.link]
      if doc.boost_phrases
        doc.boost_phrases += " #{boost}"
      else
        doc.boost_phrases = boost
      end
    end
  end
end
