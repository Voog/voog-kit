module Edicy::Liquid::Tags
  class ContentTag < Liquid::Tag
    def initialize(name, params, tokens)
      @name = name
      @params = params
      @tokens = tokens
      super
    end

    def render(context)
      match = /name=\"(.+)\"/.match(@params)
      name = (@params.length && !match.nil? ? match[1] : 'body')
      context['page'].content(name) || context['language'].content(name) if name
    end
  end
end

Liquid::Template.register_tag(:content, Edicy::Liquid::Tags::ContentTag)
