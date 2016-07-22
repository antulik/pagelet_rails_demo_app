class Pagelets::BaseController < ::ApplicationController
  include Pagelets::Concerns::Routes
  include Pagelets::Concerns::Options
  # include Pagelets::Concerns::Cache

  self.view_paths = ['app/components/', 'app/views', 'app/views_partials']

  prepend_before_action :check_parent_params

  before_action do
    lookup_context.prefixes.clear
    lookup_context.prefixes.unshift "pagelets/#{controller_name}/views"
  end

  layout :layout_name

  pagelet_options pjax: false, layout: 'body'


  def layout_name
    layout = params[:layout] || pagelet_options.layout

    "pagelets/#{layout}"
  end

  private

  def check_parent_params
    if params[:original_pagelet_options]
      opts = Encryptor::Handler.decode(params[:original_pagelet_options])
      pagelet_options(opts)
    end
  end

end
