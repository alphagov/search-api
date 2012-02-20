def sort_documents_by_index(docs, indexes)
  sorted = Hash.new{|h,k| h[k] = []}
  docs.collect { |doc| [doc.presentation_format, doc] }.each do |k|
    sorted[k[0]] << k[1]
  end
  sorted.sort { |a,b|
    index_a = indexes.index(a[0])
    index_b = indexes.index(b[0])
    if index_a && index_b
      index_a <=> index_b
    elsif index_a
      -1
    elsif index_b
      1
    else
      0
    end
  }
end

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
