module PageletRails::Concerns::Controller
  extend ActiveSupport::Concern

  included do
    include PageletRails::Concerns::Routes
    include PageletRails::Concerns::Options
    # include PageletRails::Concerns::Cache

    self.view_paths = ['app/components/', 'app/views', 'app/views_partials']

    prepend_before_action :check_parent_params

    before_action do
      lookup_context.prefixes.clear
      lookup_context.prefixes.unshift "pagelets/#{controller_name}/views"
    end

    layout :layout_name

    helper_method :pagelet_embedded?
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

  def pagelet_embedded?
    !!pagelet_options.embedded
  end

  private

  def check_parent_params
    if params[:original_pagelet_options]
      opts = Encryptor::Handler.decode(params[:original_pagelet_options])
      pagelet_options(opts)

      puts opts
      puts pagelet_options
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

  # def pagelet_render *args
  #   opts = args.extract_options!
  #   opts[:layout] ||= layout_name
  #
  #   respond_to do |format|
  #     format.js {
  #       # binding.pry
  #       # if request.headers['X-Pagelet']
  #       #   render *args, opts
  #       # else
  #         render js: render_to_element_js("##{params[:target_container]}", *args, opts)
  #       # end
  #     }
  #     format.html {
  #       render *args, opts
  #     }
  #   end
  # end

  def send_action *args
    super

    if params[:target_container] &&
      request.format.js? && self.response_body.first[0] == '<'

      response.content_type = 'text/javascript'

      self.response_body.map! do |html|
        js = ActionController::Base.helpers.escape_javascript html

        <<-EOS.html_safe
          $('##{params[:target_container]}').html('#{js}');
          $(document).trigger('pagelet-loaded');
        EOS
      end
    end

  end

end
