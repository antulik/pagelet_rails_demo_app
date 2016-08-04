module ApplicationHelper

  def li_menu text, path
    klass = 'active' if request.path == path
    content_tag :li, class: klass do
      content_tag(:a, text, href: path)
    end
  end
end
