module Edicy::Liquid::Tags
  
  class CommentFormBlock < Liquid::Block
    
    def render(context)
      'Comment form'
    end
  end
end

Liquid::Template.register_tag(:commentform, Edicy::Liquid::Tags::CommentFormBlock)
