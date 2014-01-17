module Edicy::Liquid::Tags
  class LanguageAddTag < Liquid::Tag
    def render(context)
      ''
    end
  end
end

Liquid::Template.register_tag(:languageadd, Edicy::Liquid::Tags::LanguageAddTag)
