# This field compare was created to assist in the migration of
# formats to the govuk index, it allow the following values to
# be successfully compared:
# * time fields with different formating
# * indexable content - markdown v's html
module Indexer
  class GovukIndexFieldComparer
    def stats
      @stats ||= Hash.new(0)
    end

    def call(id, key, old, new)
      return true if key =~ /^_root/
      return true if old.nil? && new == []

      if old.nil? && !new.nil?
        stats["AddedValue: #{key}"] += 1
        return true
      end
      if new.nil? && !old.nil?
        stats["RemovedValue: #{key}"] += 1
        return false
      end
      return compare_time(key, old, new) if %w(public_timestamp first_published_at).include?(key)
      return compare_content(id, old, new) if key == "indexable_content"
      return true if old.nil? && new == ""
      return true if key == "rendering_app" && old == "specialist-frontend" && new == "government-frontend"
      return compare_arrays(old, new) if old.is_a?(Array) && new.is_a?(Array)

      clean_field(old) == clean_field(new)
    end

    def compare_time(key, old, new)
      return true if Time.parse(old) == Time.parse(new)

      stats["#{Time.parse(old) > Time.parse(new) ? 'Older' : 'Newer'} value for: #{key}"] += 1
      false
    rescue TypeError
      false
    end

    def compare_content(id, old, new)
      clean_old = clean_content(remove_links(old))
      clean_new = clean_content(new)
      if clean_old == clean_new
        true
      else
        old_words = clean_old.split(" ").compact.reject { |w| w =~ /^\d+$/ }
        new_words = clean_new.split(" ").compact.reject { |w| w =~ /^\d+$/ }

        extra_old = old_words - new_words
        extra_new = new_words - old_words
        extra_old.uniq!
        extra_new.uniq!

        extra_old.reject! { |old_word| new_words.any? { |new_word| new_word =~ /^#{old_word}/ } } # ignore words that have been truncated
        diff_per = (200.0 * extra_old.count / (old_words.count + new_words.count))
        if extra_old.count.zero?
          # we don't need to worry too much about additional words being added
          true
        elsif diff_per < 2
          # if the page has less than X % difference then we are just going to say it is close enough
          # This should be reviewed with the Product Manager
          true
        else
          stats["Indexable Content word diff: #{extra_old.count}"] += 1
          # These are the real difference as are printed to the screen so they can be review on an individual basis
          puts "Mismatch content [#{id}]: #{diff_per.round(2)}\nREMOVED: #{extra_old.join(', ')}\nADDED: #{extra_new.join(', ')}\n\n"
          false
        end
      end
    end

    def compare_arrays(old, new)
      old.map { |i| clean_field(i) } == new.map { |i| clean_field(i) }
    end

    def remove_links(str)
      str.gsub(/\[([^\]]*(?:\[[^\]]*\][^\]]*)?)\]\([^\)]*\)/, ' \1 ') # [name](link) => name
        .gsub(/#+\s*/, " ")
        .gsub(/\[InlineAttachment:(?:.*\/)?([^\[\]\/]*(?:\[[^\]\/]*\][^\[\]\/]*|)*)\]/, '\1')
    end

    def clean_field(str)
      str.gsub(/[’'‘]/, "'")
    end

    def clean_content(str)
      (str || "")
        .downcase # normalise case
        .gsub(/\.[a-z]{3}(\)| |$)/, '\1') # hash as sometimes the link will have the extension
        .gsub(/[\s,\-_:\/–\[\]\(\)\.\*\|\\\"“”]+/, " ") # remove all special characters
        .gsub(/&amp;/, "&")
        .gsub(/[’'‘]/, "'")
        .gsub(/ /, " ") #nbsp
    end
  end
end
