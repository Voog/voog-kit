module Edicy::Liquid::Drops
  class ArticleDrop < Liquid::Drop
  
    def initialize(article)
      @article = article
    end
    
    # Returns an integer to uniquely identify article on system.
    def id
      1
    end
    
    # Returns <tt>true</tt> if this article has not been saved into database
    def new_record?
      false
    end
    
    # Returns title of this article
    def title
      @article.title
    end
    
    # Returns PersonDrop to access author properties
    def author
      PersonDrop.new(Data.person(@article.author)).to_liquid
    end
    
    # Returns PageDrop to access page properties
    def page
      p = Data.page(@article.page)
      PageDrop.new(p, page) unless p.nil?
    end
    
    # Absolute url for article. If article path is <tt>neat_article</tt> and it is under <tt>blog</tt> page, the url might
    # be something like <tt>mysite/blog/neat_article</tt>
    def url
      '/' + [@article.page, @article.path] * '/'
    end
    
    # Returns all published comments as CommentDrop objects in order of their creation time.
    #
    # For example, looping through all the comments for current article:
    #
    #   {% for comment in article.comments %}<p>{{ comment.body }}</p>{% endfor %}
    #
    def comments
      @article.comments.inject(Array.new) do |a, c|
        a << CommentDrop.new(c).to_liquid
        a
      end unless @article.comments.nil?
    end
    
    # Number of comments associated with this article
    def comments_count
      if @article.comments.nil? then 0 else @article.comments.size end
    end
    
    # Returns an URL where new comments for this article should be submitted to. Used to build comment forms.
    #
    #   <form action="{{ action.comments_url }}" method="post">...</form>
    #
    def comments_url
    end
    
    # Returns excerpt of this article
    def excerpt
      @article.excerpt
    end
    
    def page_id
      1
    end
    
    # Returns body of this article
    def body
      @article.body
    end
    
    # Date object representing when this article has been created. Use <tt>date</tt> filter to format it.
    #
    #   {{ article.created_at | date:"%d.%m.%Y" }}
    #
    def created_at
      @article.created_at
    end
    
    # Date object representing when this article has been updated. Use <tt>date</tt> filter to format it.
    #
    #   {{ article.created_at | date:"%d.%m.%Y" }}
    #
    def updated_at
      @article.updated_at
    end
  end
end
