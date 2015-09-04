require 'nokogiri'
require 'open-uri'

class SubWord
  attr_accessor(
    :word,       # a string
    :relevance,  # positive is synonym, negative is antonym
    :length,     # an Integer (relative, not true)
    :complexity, # an Integer
    :common      # a bool 
  )
  
  def initialize(word,relevance,length,complexity, common)
    @word = word
    @relevance = relevance
    @length = length
    @complexity = complexity
    @common = common
  end

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :word
    expose :relevance
    expose :length
    expose :complexity
    expose :common
  end
end

class Word
  attr_reader(
    :word,
    :part_of_speech,
    :similar,
    :synonyms
  )

  def initialize(word,pos,sim)
    @word = word
    @part_of_speech = pos
    @similar = sim
  end

  def add_synonym(word)
    if @synonyms.nil?
      @synonyms = [word]
    else
      @synonyms << word
    end
  end

  def self.fetch(word)
    doc = Nokogiri::HTML(open("http://www.thesaurus.com/browse/#{word}"))
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
      similar = desc.css('.ttl').text.split(', ')

      syn_group = Word.new(word, part_of_speech, similar)

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
        syn_word = w.css('.text').text

        # string((//*[@class='synonyms'][1]//ul//li//a)[1]/@class)
        common = w.attr('class').eql? "common-word"
        word_obj = SubWord.new(syn_word, relevance, length, complexity, common)
        syn_group.add_synonym(word_obj)
      end
      groups << syn_group
    end
    groups
  end

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :word
    expose :part_of_speech
    expose :similar
    expose :synonyms
  end
end

module Synonymous
  class Words < Grape::API
    get ':word' do
      words = Word.fetch(params[:word])
      present words
    end
  end
end
