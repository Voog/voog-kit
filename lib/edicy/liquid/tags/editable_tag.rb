module Edicy::Liquid::Tags
  class EditableTag < Liquid::Tag
    def initialize(name, params, tokens)
      @name = name
      @params = params
      @tokens = tokens
      super
    end

    def render(context)
      return unless @params && @params.split('.').length > 1
      obj, field = @params.split('.').map(&:strip)
      env = context.environments[0]
      obj = env[obj] || (env.respond_to?(:obj) ? env.obj : nil)
      obj[field] || (obj.respond_to?(:field) ? obj.field : nil)
    end
  end
end

Liquid::Template.register_tag(:editable, Edicy::Liquid::Tags::EditableTag)
