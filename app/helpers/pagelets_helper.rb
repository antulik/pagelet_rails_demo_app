module PageletsHelper

  def silence_log message, options = {}
    options[:level] ||= :info

    result = nil
    ms = nil
    capture(:stdout) do
      ms = Benchmark.ms do
        result = yield
      end
    end

    if message.present?
      Rails.logger.send(options[:level],
        message: message,
        duration: ms.round(2)
      )
    end

    result
  end

  def pagelet *args
    html_opts = args.extract_options!

    silence_log "Pagelet rendered #{args}" do
      controller = nil
      action = nil

      case args.size
      when 1
        path = args[0]
        path_opts = Rails.application.routes.recognize_path(path)
        controller = path_opts[:controller].camelize.concat('Controller').constantize
        action = path_opts[:action]

      when 2
        name, action = *args
        controller = "Pagelets::#{name.to_s.camelize}::#{name.to_s.camelize}Controller".constantize
      end

      c = controller.new

      pagelet_params = html_opts.delete(:params) { {} }
      pagelet_params.reverse_merge!(params.except(:controller, :action))
        .merge!(controller: c.controller_path, action: action)

      pagelet_options = pagelet_extract_opts!(html_opts)
      pagelet_options = pagelet_options.deep_merge(
        html_opts: html_opts,
        parent_params: params
      )

      PageletHookModule.apply_hook c, action

      c.pagelet_options pagelet_options
      c.params = pagelet_params

      env = request.env.deep_dup
      pagelet_request = ActionDispatch::Request.new(env)
      pagelet_request.parameters.merge! pagelet_params

      pagelet_response        = controller.make_response! pagelet_request
      c.dispatch(action, pagelet_request, pagelet_response)

      body = c.response.body
      body.html_safe
    end
  end

  def pagelet_extract_opts!(html_opts)
    result = html_opts.extract!(:height, :pjax, :remote)
    result.merge!(html_opts.delete(:pagelet_options) { {} })
    result
  end

  # This is hack to simulate before_action.
  # For some reasons rendering in before_action is 8 times slower
  # than in action itself, so this is hack to do that.
  module PageletHookModule
    def self.apply_hook controller_instance, action
      define_action_method_if_missing action
      controller_instance.extend self
    end

    def self.define_action_method_if_missing action
      return if method_defined? action

      module_exec do
        define_method(action) do
          return super() if action_name.to_s != __callee__.to_s

          render_remote_load
          super() if !performed?
        end
      end
    end

    def render_remote_load
      return unless pagelet_options.remote

      encode_data = @pagelet_options.fetch('default').except('remote')
      original_pagelet_options = Encryptor::Handler.encode(encode_data)

      data = params.merge(original_pagelet_options: original_pagelet_options)
      data.permit!

      pagelet_options html_opts: { 'data-widget-url' => url_for(data) }

      if pagelet_options.loading_placeholder
        instance_exec &pagelet_options.loading_placeholder
      else
        render 'layouts/pagelets/loading_placeholder', layout: layout_name
      end
    end
  end

end
