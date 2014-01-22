module Edicy::Liquid::Tags
  class RemoveButtonTag < Liquid::Tag
    def render(context)
      style = %(border: 1px dashed grey !important; border-radius: 10px !important; padding: 0 5px 0 5px !important;)
      %(
        <a style="#{style}" class="edy-cbtn edy-cbtn-lonely edy-menu-removebutton" href="#" title="Remove">
          <span class="edy-cbtn-text">Remove</span>
        </a>
      )
    end
  end
end

Liquid::Template.register_tag(:removebutton, Edicy::Liquid::Tags::RemoveButtonTag)
