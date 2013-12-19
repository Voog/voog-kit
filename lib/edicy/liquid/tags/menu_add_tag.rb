module Edicy::Liquid::Tags
  
  class MenuAddTag < Liquid::Tag
    
    def render(context)
      '+ Add'
    end
  end
end

Liquid::Template.register_tag(:menuadd, Edicy::Liquid::Tags::MenuAddTag)
