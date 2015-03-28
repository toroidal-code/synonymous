module Synonymous
  class Word < Grape::API
    get ':word' do
      { word: params[:word] }
    end
  end
end
