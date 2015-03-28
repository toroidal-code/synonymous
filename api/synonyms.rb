module Synonymous
  class Synonyms < Grape::API
    get '/:word/synonyms' do
      { word_synonyms: params[:word] }
    end
  end
end
