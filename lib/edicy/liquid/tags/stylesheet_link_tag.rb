module Edicy::Liquid::Tags
  class StylesheetLinkTag < Liquid::Tag
    def initialize(name, params, tokens)
      @name = name
      @params = params
      @tokens = tokens
      super
    end

    def render(context)
      stylesheet = /\"(.+)\"/.match(@params)[1]
      %(<link href="./stylesheets/#{stylesheet}" media="#{@media}" rel="stylesheet" type="text/css" />)
    end
  end
end

Liquid::Template.register_tag(:stylesheet_link, Edicy::Liquid::Tags::StylesheetLinkTag)
