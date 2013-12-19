module Edicy::Liquid::Tags
  
  class MenuBtnTag < Liquid::Tag
    
    def render(context)
      '+ Add'
    end
  end
end

Liquid::Template.register_tag(:menubtn, Edicy::Liquid::Tags::MenuBtnTag)
