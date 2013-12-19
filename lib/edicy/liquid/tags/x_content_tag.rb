module Edicy::Liquid::Tags
  
  class XContentTag < Liquid::Tag
    
    def render(context)
      'Content'
    end
  end
end

Liquid::Template.register_tag(:xcontent, Edicy::Liquid::Tags::XContentTag)
