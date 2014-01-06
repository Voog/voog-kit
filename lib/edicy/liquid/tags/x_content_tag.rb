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
      name = match[1] if match
      context["page"].content(name) || context["language"].content(name) if name
    end
  end
end

Liquid::Template.register_tag(:xcontent, Edicy::Liquid::Tags::XContentTag)
