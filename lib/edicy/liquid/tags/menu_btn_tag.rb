module Edicy::Liquid::Tags
  # TODO: Implement menubtn
  class MenuBtnTag < Liquid::Tag
    def initialize(name, params, tokens)
      super
      @name = name
      @params = params
      @tokens = tokens
    end

    def render(context)
      obj = context[@params.strip]
      return "" if obj.respond_to?(:each) && obj.count == 0
      if obj.respond_to?(:each) && obj.all? { |o| o.respond_to?(:hidden?) && o.hidden? }
        %(<a href="#">#{obj.count} hidden</a>)
      else
        %(<a href="#">#{obj.title}</a>)
      end
    end
  end
end

Liquid::Template.register_tag(:menubtn, Edicy::Liquid::Tags::MenuBtnTag)
