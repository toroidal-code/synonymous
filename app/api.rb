module Synonymous
  class API < Grape::API
    format :json
    mount ::Synonymous::Words
  end
end
