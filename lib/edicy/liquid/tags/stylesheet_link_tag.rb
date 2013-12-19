module Edicy::Liquid::Tags
  
  class StylesheetLinkTag < Liquid::Tag
    
    def render(context)
      %(<link href="./stylesheets/style.css" media="#{@media}" rel="stylesheet" type="text/css" />)
    end
  end
end

Liquid::Template.register_tag(:stylesheet_link, Edicy::Liquid::Tags::StylesheetLinkTag)
