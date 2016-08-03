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

    pagelet_options pjax: false, layout: 'panel'
  end

  def layout_name
    layout = params[:layout] || pagelet_options.layout

    if pagelet_options.pjax && request.xhr?
      "pagelets/inner"
    else
      "pagelets/#{layout}"
    end

  end

  def pagelet_embedded?
    !!pagelet_options.embedded
  end

  private

  def check_parent_params
    if params[:original_pagelet_options]
      opts = Encryptor::Handler.decode(params[:original_pagelet_options])
      pagelet_options(opts)
    end
  end

end
