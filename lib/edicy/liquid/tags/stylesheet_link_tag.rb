module Edicy::Liquid::Tags
  class StylesheetLinkTag < Liquid::Tag
    def initialize(name, params, tokens)
      @name = name
      @params = params
      @tokens = tokens
      @stylesheet = /\"(.+)\"/.match(@params)[1]

      @static_host = /static_host=\"(true|false)\"/.match(@params)
      @static_host = @static_host ? @static_host[1] == "true" : false

      @media = /media=\"(.+)\"/.match(@params)
      @media = (@media ? @media[1] : 'screen').strip
      super
    end

    def render(context)
      %(<link href="#{stylesheet_path}" media="#{@media}" rel="stylesheet" type="text/css" />)
    end

    private 

    def stylesheet_path
      './stylesheets/' + @stylesheet
    end
  end
end

Liquid::Template.register_tag(:stylesheet_link, Edicy::Liquid::Tags::StylesheetLinkTag)
