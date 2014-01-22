module Edicy::Liquid::Tags
  class AddButtonTag < Liquid::Tag

    def initialize(name, params, tokens)
      super
      @name = name
      @params = params
      @tokens = tokens
    end

    def render(context)
      blog = context['page'].blog?
      style = %(border: 1px dashed grey !important; border-radius: 10px !important; padding: 0 5px 0 5px !important;)
      %(
        <a class="edy-cbtn edy-cbtn-lonely edy-site-menu-add add-#{blog ? 'article' : 'element'}" href="#" style="#{style}">
          <span class="edy-cbtn-ico">
            <svg width="14" height="14" xmlns="http://www.w3.org/2000/svg">
             <path d="M8 6v-5h-2v5h-5v2h5v5h2v-5h5v-2h-5z" fill="currentColor"></path>
            </svg>
          </span>
          <span class="edy-cbtn-text">New #{blog ? 'post' : 'element'}</span>
        </a>
      )
    end
  end
end

Liquid::Template.register_tag(:addbutton, Edicy::Liquid::Tags::AddButtonTag)
