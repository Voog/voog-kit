module Edicy::Liquid::Tags
  # TODO: Implement menubtn
  class MenuBtnTag < Liquid::Tag
    def render(context)
      ''
    end
  end
end

Liquid::Template.register_tag(:menubtn, Edicy::Liquid::Tags::MenuBtnTag)
