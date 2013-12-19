module Edicy::Liquid::Tags
  
  class EditableTag < Liquid::Tag
    
    def render(context)
      'Editable'
    end
  end
end

Liquid::Template.register_tag(:editable, Edicy::Liquid::Tags::EditableTag)
