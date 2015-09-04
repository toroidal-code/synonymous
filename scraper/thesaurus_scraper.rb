#! /usr/bin/env ruby
require 'nokogiri'
require 'open-uri'
require 'json'
#require 'trollop'


class SynonymGroup
  @part_of_speech # a symbol
  @similar        # an array of similar words as strings
  @words          # an array of word objects

  def initialize(pos,sim)
    @part_of_speech = pos
    @similar = sim
    @words = []
  end

  def add_word(word)
    @words << word
  end

  def to_hash
    {
      part_of_speech: @part_of_speech,
      similar: @similar,
      words: @words.map(&:to_hash)
    }
  end

  def to_json(opts)
    JSON.generate to_hash, opts
  end
end

class Word
  @relevance  # positive is synonym, negative is antonym
  @complexity # an Integer
  @length     # an Integer (relative, not true)
  @word       # a string
  @common     # a bool 

  def initialize(word,relevance,length,complexity, common)
    @word = word
    @relevance = relevance
    @length = length
    @complexity = complexity
    @common = common
  end
  
  def to_hash
    {
      relevance: @relevance,
      complexity: @complexity,
      length: @length,
      common: @common,
      word: @word
    }
  end

  def to_json(opts)
    JSON.generate to_hash, opts
  end
end

# http://restapi.dictionary.com/v2/word.json/help/synonyms?api_key=sWq3tLz8ifndaTK

req_word = ARGV[0].to_s
doc = Nokogiri::HTML(open("http://www.thesaurus.com/browse/#{req_word}"))
groups = []

# //*[@class='synonyms']
doc.css('.synonyms').each do |g|
  
  # //*[@class='synonym-description')]
  #
  # //*[@class='synonyms'][idx]//*[@class='synonym-description']
  desc = g.css('.synonym-description').first
  
  # //*[@class='txt']
  #
  # //*[@class='synonyms'][idx]//*[@class='synonym-description'][1]/*[@class='txt']/text()
  part_of_speech = desc.css('.txt').text.to_sym
  
  # //*[contains(concat(' ', normalize-space(@class), ' '), ' ttl ')]
  #
  # //*[@class='synonyms'][idx]//*[@class='synonym-description'][1]/*[@class='ttl']/text()
  similar = desc.css('.ttl').text.split(', ')# .map(&:strip)

  syn_group = SynonymGroup.new(part_of_speech, similar)

  # //ul//li//a
  #
  # //*[@class='synonyms'][idx]//ul//li//a
  words = g.css('ul li a')
  words.each do |w|
    # for some reason, data-category is a json object that holds the relevance info
    # we then split the string 'relevant-3' on '-', and take the second, turning it
    # into an Integer in the process
    #

    # string((//*[@class='synonyms'][idx]//ul//li//a)[jdx]/@data-category)
    relevance = JSON.parse(w.attr('data-category'))['name'].split('-',2)[1].to_i

    # number((//*[@class='synonyms'][idx]//ul//li//a)[jdx]/@data-complexity)
    complexity = w.attr('data-complexity').to_i   # relative complexity

    # number((//*[@class='synonyms'][idx]//ul//li//a)[jdx]/@data-complexity)
    length = w.attr('data-length').to_i           # relative length

    # string((//*[@class='synonyms'][idx]//ul//li//a)[1]//*[@class='text'])
    word = w.css('.text').text

    # string((//*[@class='synonyms'][1]//ul//li//a)[1]/@class)
    common = w.attr('class').eql? "common-word"
    word_obj = Word.new(word, relevance, length, complexity, common)
    syn_group.add_word(word_obj)
  end
  groups << syn_group
end

puts JSON.pretty_generate(groups)
