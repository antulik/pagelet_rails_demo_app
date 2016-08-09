module PageletRails::Concerns::Controller
  extend ActiveSupport::Concern

  included do
    include PageletRails::Concerns::Routes
    include PageletRails::Concerns::Options
    # include PageletRails::Concerns::Cache
    # include PageletRails::Concerns::CacheOne
    include PageletRails::Concerns::CacheTwo

    prepend_before_action :check_parent_params

    before_action do
      self.view_paths.unshift 'app/pagelets/'

      # lookup_context.prefixes.clear
      view = "#{controller_name}/views"
      if lookup_context.prefixes.exclude?(view)
        lookup_context.prefixes.unshift "#{controller_name}/views"
      end


      # https://github.com/rails/actionpack-action_caching/issues/32
      if lookup_context.formats.exclude?(:html)
        lookup_context.formats.unshift :html
      end
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

  def process_action *args
    super.tap do
      if params[:target_container] &&
        action_has_layout? &&
        request.format.js? #&& self.response_body.first[0] == '<'

        response.content_type = 'text/javascript'

        html = self.response_body.reduce('') { |memo, body|
          memo << body
          memo
        }

        id = ActionController::Base.helpers.escape_javascript params[:target_container]
        js = ActionController::Base.helpers.escape_javascript html

        html = ActionController::Base.helpers.raw(
          "pagelet_place_into_container('#{id}', '#{js}');"
        )

        self.response_body = [html]
      end
    end
  end

  def pagelet_render_remotely?
    case pagelet_options.remote
    when :stream
      render_remotely = true
    when :turbolinks
      # render now if request coming from turbolinks
      is_turbolinks_request = !!request.headers['Turbolinks-Referrer']
      render_remotely = !is_turbolinks_request
    when true
      render_remotely = true
    else
      render_remotely = false
    end

    render_remotely
  end

end
