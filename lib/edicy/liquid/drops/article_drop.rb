module Edicy::Liquid::Drops
  class ArticleDrop < Liquid::Drop
    def initialize(article)
      @article = article
    end

    def title
      @article.title
    end

    def excerpt
      @article.excerpt
    end

    def created_at
      @article.created_at
    end

    def comments_count
      @article.comments_count
    end

    def body
      @article.body
    end

    def created_by
      @article.created_by
    end

    def language
      @article.language
    end

    def path
      @article.path
    end

    def url
      [@article.parent_path, @article.path + '.html'] * '/'
    end
  end
end
