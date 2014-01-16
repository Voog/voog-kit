module Edicy::Liquid::Tags
  
  class XContentTag < Liquid::Tag
    
    def initialize(name, params, tokens)
      @name = name
      @params = params
      @tokens = tokens
      super
    end

    def render(context)
      match = /name=\"(.+)\"/.match(@params)
      name = match ? match[1] : 'body'
      context["language"].content(name) || context["page"].content(name) if name
    end
  end
end

Liquid::Template.register_tag(:xcontent, Edicy::Liquid::Tags::XContentTag)
