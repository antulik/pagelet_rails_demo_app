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
    opts = args.extract_options!

    silence_log "Pagelet rendered #{args}" do
      controller = nil
      action = nil
      pagelet_params = opts.delete(:params) { {} }.with_indifferent_access

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

      c = controller.new


      pagelet_params.reverse_merge!(params.except(:controller, :action))
        .merge!(controller: c.controller_path, action: action)

      pagelet_options = opts.deep_merge(
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
      case pagelet_options.remote
      when :turbolinks
        # render now if request coming from turbolinks
        is_turbolinks_request = !!request.headers['Turbolinks-Referrer']
        return if is_turbolinks_request
      when true
        # keep going and render placeholder
      else
        # render now
        return
      end

      data = params.deep_dup
      data.permit!

      pagelet_options html: { 'data-widget-url' => url_for(data) }

      default_view = 'layouts/pagelets/loading_placeholder'
      view = pagelet_options.placeholder.try(:[], :view).presence || default_view

      render view
    end

  end

end
