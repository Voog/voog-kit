module Edicy::Liquid::Tags
  
  class ContentBlockTag < Liquid::Block
    
    def initialize(name, params, tokens)
      super
      @name = name
      @params = params
      @tokens = tokens
    end

    def render(context)
      match = /name=\"(.+)\"/.match(@params)
      name = ( @params.length && !match.nil? ? match[1] : 'body' )
      content = context["page"].content(name) || context["language"].content(name) if name
      if content
        content
      else
        super
      end
    end
  end
end

Liquid::Template.register_tag(:contentblock, Edicy::Liquid::Tags::ContentBlockTag)
