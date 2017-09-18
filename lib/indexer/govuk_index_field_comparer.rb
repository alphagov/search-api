# This field compare was created to assist in the migration of
# formats to the govuk index, it allow the following values to
# be successfully compared:
# * time fields with different formating
# * indexable content - markdown v's html
module Indexer
  class GovukIndexFieldComparer
    def call(key, old, new)
      return compare_time(old, new) if key == 'public_timestamp'
      return compare_content(old, new) if key == 'indexable_content'
      old == new
    end

    def compare_time(old, new)
      Time.parse(old) == Time.parse(new)
    rescue TypeError
      false
    end

    def compare_content(old, new)
      clean_old = clean_content(old)
      clean_new = clean_content(new)
      if clean_old == clean_new
        true
      else
        old_words = clean_old.split(' ')
        new_words = clean_new.split(' ')

        extra_old = old_words - new_words
        diff = extra_old + (new_words - old_words)
        diff_per = (200.0 * diff.count / (old_words.count + new_words.count))
        if extra_old.count == 0
          # we don't need to worry too much about additional words being added
          return true
        elsif clean_old =~ /https assets.digital.cabinet office.gov.uk/
          # This is an issue with the link in the markdown, we should regex this out as a better solution
          puts "link: #{old}"
          return false
        elsif diff_per < 5
          # if the page has less than X % difference then we are just going to say it is close enough
          # This should be reviewed with the Product Manager
          return true
        else
          # These are the real difference as are printed to the screen so they can be review on an individual basis
          puts "Mismatch content: #{diff_per.round(2)} : #{diff.length}\n`#{clean_old}`\n!=\n`#{clean_new}`\n\n"
          false
        end
      end
    end

    def clean_content(str)
      (str || '')
        .gsub(/\[InlineAttachment:([^\]]*)\.[^\.]*\]/) { $1.tr('_', ' ') } # remove inline attachment text
        .downcase # normalise case
        .gsub(/\.[a-z]{3}( |$)/, '\1') # hash as sometimes the link will have the extension
        .gsub(/[\s,\-_:\/]+/, ' ') # remove all special characters
    end
  end
end
