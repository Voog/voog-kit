module Edicy::Liquid::Tags
  
  class ContentTag < Liquid::Tag
    
    def initialize(name, params, tokens)
      @name = name
      @params = params
      @tokens = tokens
      super
    end

    def render(context)
      name = @params.length ? /name=\"(.+)\"/.match(@params)[1] : 'body'
      context["page"].content(name) || context["language"].content(name) if name
    end
  end
end

Liquid::Template.register_tag(:content, Edicy::Liquid::Tags::ContentTag)
