module Edicy::Liquid::Tags
  class AddButtonTag < Liquid::Tag
    def render(context)
      ''
    end
  end
end

Liquid::Template.register_tag(:addbutton, Edicy::Liquid::Tags::AddButtonTag)
