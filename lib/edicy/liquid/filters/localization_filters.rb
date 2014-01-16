module Edicy::Liquid::Filters
  
  module LocalizationFilters

    def lc(input)
      return unless input
      str = LocalizationStrings.fetch(input, nil)
      str || input.downcase.gsub("_", " ").capitalize
    end
          
    def ls(input)
      lc(input)
    end

    LocalizationStrings = {
      "comment" => "Comment",
      "latest_news" => "Latest news",
      "name" => "Name",
      "author" => "Author",
      "comment_author_blank" => "Name is empty!",
      "comments" => "Comments",
      "footer_login_link" => "Edicy. Make a website.",
      "submit" => "Submit",
      "comment_body_blank" => "Comment is empty!",
      "add_a_comment" => "Add a comment",
      "search_close" => "Close",
      "forms.submit_form" => "Submit",
      "forms.form_submitted" => "Form has been submitted. Thank you!",
      "forms.invalid_email_format" => "Invalid e-mail format",
      "forms.template.comments" => "Comments and notes",
      "forms.template.your_name" => "Your name",
      "forms.template.your_email" => "Your email address",
      "forms.field_is_required" => "Field is required",
      "forms.file_is_too_large" => "Cannot upload files larger than 4 megabytes",
      "forms.ticket_invalid_data" => "Invalid data has been submitted!",
      "forms.file_is_required" => "File is required",
      "submit_comment" => "Submit comment",
      "comments_for_count" => "Comments",
      "email_wont_be_published" => "E-mail won't be published",
      "no_comments" => "No comments",
      "write_first_comment" => "Write first comment",
      "comment_email_blank" => "E-mail is empty!",
      "latest_article" => "Latest article",
      "news" => "News",
      "search_noresults" => "Your search did not match any documents",
      "email" => "E-mail",
      "older_news" => "Older news",
      "read_more" => "Read more",
      "search" => "Search",
      "title_goes_here" => "Title goes here",
      "posts_tagged" => "Posts tagged",
      "no_posts_tagged" => "There are no posts tagged.",
      "filter_by_tags" => "Filter by tags",
      "tags" => "Tags:",
      "older" => "Older",
      "newer" => "Newer"
    }

  end
end

Liquid::Template.register_filter(Edicy::Liquid::Filters::LocalizationFilters)
