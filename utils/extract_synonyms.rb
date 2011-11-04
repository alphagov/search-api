#!/usr/bin/env ruby

# Directgov can output an XML file of synonyms which has been imported into
# the solr puppet module in the correct format. This script extracts
# the synonyms and outputs the correct format

require 'rexml/document'

file = File.new("synonyms.xml")
doc = REXML::Document.new file

doc.elements.each('synonyms/ns2:SynonymSet') do |ele|
  synonyms = []
  synonyms << ele.attributes['originalExpr']
  ele.children.each do |child|
    begin
      synonyms << child.attributes['alternativeExpr']
    rescue
    end
  end
  puts synonyms.join(',')
end
