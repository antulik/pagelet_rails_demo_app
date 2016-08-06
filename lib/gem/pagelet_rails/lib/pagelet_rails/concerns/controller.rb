module PageletRails::Concerns::Controller
  extend ActiveSupport::Concern

  included do
    include PageletRails::Concerns::Routes
    include PageletRails::Concerns::Options
    # include PageletRails::Concerns::Cache
    # include PageletRails::Concerns::CacheOne
    include PageletRails::Concerns::CacheTwo

    self.view_paths.unshift 'app/pagelets/'

    prepend_before_action :check_parent_params

    before_action do
      lookup_context.prefixes.clear
      lookup_context.prefixes.unshift "#{controller_name}/views"
    end

    layout :layout_name

    helper_method :pagelet_request?

    pagelet_options layout: 'panel'
  end

  def layout_name
    layout = params[:layout] || pagelet_options.layout

    "pagelets/#{layout}"
  end

  def pagelet_request?
    request.headers['X-Pagelet'].present? || params[:target_container]
  end

  private

  def check_parent_params
    if params[:original_pagelet_options]
      opts = PageletRails::Encryptor.decode(params[:original_pagelet_options])
      pagelet_options(opts)
    end
  end

  def render_to_element_js element_selector, *args
    html = render_to_string *args
    js = ActionController::Base.helpers.escape_javascript html
    <<-EOS.html_safe
      $('#{element_selector}').html('#{js}');
      $(document).trigger('pagelet-loaded');
    EOS
  end

  def process_action *args
    super.tap do
      if params[:target_container] &&
        action_has_layout? &&
        request.format.js? && self.response_body.first[0] == '<'

        response.content_type = 'text/javascript'

        html = self.response_body.reduce('') { |memo, body|
          memo << body
          memo
        }

        js = ActionController::Base.helpers.escape_javascript html

        html = <<-EOS.html_safe
        $('##{params[:target_container]}').html('#{js}');
        $(document).trigger('pagelet-loaded');
        EOS

        self.response_body = [html]
      end
    end
  end

end
