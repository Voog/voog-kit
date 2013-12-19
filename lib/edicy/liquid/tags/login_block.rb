module Edicy::Liquid::Tags
  
  class LoginBlock < Liquid::Block
    
    def render(context)
      output = super
      
      "<a href=\"http://www.edicy.com\">#{output}</a>"
    end
  end
end

Liquid::Template.register_tag(:loginblock, Edicy::Liquid::Tags::LoginBlock)
