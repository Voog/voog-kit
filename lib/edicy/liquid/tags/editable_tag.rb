module Edicy::Liquid::Tags
  
  class EditableTag < Liquid::Tag

    def initialize(name, params, tokens)
      @name = name
      @params = params
      @tokens = tokens
      super
    end

    def render(context)
      obj, field = @params.split(".").map(&:strip)
      context.environments[0][obj][field.to_sym]
    end
  end
end

Liquid::Template.register_tag(:editable, Edicy::Liquid::Tags::EditableTag)
