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

  def pagelet_stream
    return nil if pagelet_stream_objects.empty?
    pagelet_stream_objects.each do |key, block|
      concat content_tag('script', raw("pagelet_place_into_container('#{key}', '#{j capture(&block)}');\n"), type: 'text/javascript')
    end
    nil
  end

  def pagelet_default_id
    "pagelet_#{rand(2**60).to_s(36)}"
  end

  def add_pagelet_stream key, &block
    objects = pagelet_stream_objects
    raise "duplicate key: #{key}" if objects.has_key?(key)
    objects[key] = block
    request.instance_variable_set(:@pagelet_stream_objects, objects)
  end

  def pagelet_stream_objects
    request.instance_variable_get(:@pagelet_stream_objects) || {}
  end

  def pagelet *args
    pagelet_options = args.extract_options!

    silence_log "Pagelet rendered #{args}" do
      controller = nil
      action = nil
      pagelet_params = pagelet_options.delete(:params) { {} }.with_indifferent_access

      case args.size
      when 1
        path = args[0]
        if path.is_a? Symbol
          path = self.send("#{path}_path", pagelet_params)
        end

        path_opts = Rails.application.routes.recognize_path(path)
        controller = path_opts[:controller].camelize.concat('Controller').constantize
        action = path_opts[:action]

      when 2
        name, action = *args
        controller = "Pagelets::#{name.to_s.camelize}::#{name.to_s.camelize}Controller".constantize
      end

      if pagelet_options[:remote] == :stream
        id = pagelet_options.dig(:html, :id) || pagelet_default_id
        pagelet_options.deep_merge! html: { id: id }

        add_pagelet_stream id, &Proc.new {
          puts pagelet_options.inspect.red
          pagelet *args, pagelet_options.merge(remote: false, skip_container: true)
        }
      end

      c = controller.new

      pagelet_params.reverse_merge!(params.except(:controller, :action))
        .merge!(controller: c.controller_path, action: action)

      pagelet_options = pagelet_options.deep_merge(
        parent_params: params.to_h,
      )

      PageletHookModule.apply_hook c, action

      c.pagelet_options pagelet_options
      c.pagelet_options original_options: pagelet_options
      # c.params = pagelet_params

      env = request.env.deep_dup
      pagelet_request = ActionDispatch::Request.new(env)
      pagelet_request.parameters.merge! pagelet_params

      pagelet_response        = controller.make_response! pagelet_request
      c.dispatch(action, pagelet_request, pagelet_response)

      body = c.response.body
      body.html_safe
    end
  end

  # This is hack to simulate before_action.
  # For some reasons rendering in before_action is 8 times slower
  # than in action itself, so this is hack to do that.
  #
  # it will be called after before_hooks and before action
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
      render_remotely = pagelet_render_remotely?
      if render_remotely && pagelet_options.has_cache
        render_remotely = false
      end

      return unless render_remotely

      data = params.deep_dup
      data.permit!

      if pagelet_options.remote != :stream
        pagelet_options html: { 'data-widget-url' => url_for(data) }
      end

      default_view = '/layouts/pagelet_rails/loading_placeholder'
      view = pagelet_options.placeholder.try(:[], :view).presence || default_view

      render view
    end

  end

end
