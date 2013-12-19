module Edicy::Liquid::Tags
  
  class ContentTag < Liquid::Tag
    
    def render(context)
      'Content'
    end
  end
end

Liquid::Template.register_tag(:content, Edicy::Liquid::Tags::ContentTag)
