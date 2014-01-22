module Edicy::Liquid::Tags
  class RemoveButtonTag < Liquid::Tag
    def render(context)
      'Remove'
    end
  end
end

Liquid::Template.register_tag(:removebutton, Edicy::Liquid::Tags::RemoveButtonTag)
