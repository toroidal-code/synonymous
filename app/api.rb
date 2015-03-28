module Synonymous
  class API < Grape::API
    format :json
    mount ::Synonymous::Word
    mount ::Synonymous::Synonyms
  end
end
