module Edicy::Liquid::Drops
  class LanguageDrop < Liquid::Drop
    def initialize(language)
      @language = language
    end

    def content(key)
      content = @language.contents.select { |c| c.name == key }.first
      if content
        content.text.body
      else
        nil
      end
    end

    def url
      @language.code
    end

    def title
      @language.title
    end

    def selected?
      false
    end
  end
end
