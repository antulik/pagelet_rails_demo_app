module Pagelets::Concerns

  module Cache
    extend ActiveSupport::Concern

    module ClassMethods
      def check_cached_version(*actions)
        return unless cache_configured?

        options = actions.extract_options!
        options[:layout] = true unless options.key?(:layout)
        filter_options = options.extract!(:if, :unless).merge(only: actions)
        cache_options  = options.extract!(:layout, :cache_path).merge(store_options: options)

        before_action PageletCacheFilter.new(cache_options), filter_options
      end

      def pagelet_cache *args, &block
        cache_opts = args.extract_options!

        default_cache_path = cache_opts.delete(:default_cache_path) { true }
        raise ArgumentError if !block && !default_cache_path

        cache_path = Proc.new do

          if default_cache_path
            opts = params.except(:controller, :action).merge(
              controller: controller_path,
              action: action_name,
              subdomain: request.subdomain,
              current_user_id: current_user.id,
              current_user_class: current_user.class.name
            )
            opts.except! '_pjax', 'original_pagelet_options'
          else
            opts = {}
          end

          if block
            opts.merge! instance_exec(&block)
          end

          opts
        end

        cache_opts.reverse_merge!(
          expires_in: 30.minutes,
          cache_path: cache_path,
          layout: true
        )

        check_cached_version *(args.deep_dup), cache_opts.deep_dup

        cache_opts = cache_opts.merge(
          if: -> { !pagelet_options.remote }
        )

        caches_action *args, cache_opts
      end
    end

    # took original code from ActionController::Caching::Actions::ActionCacheFilter
    class PageletCacheFilter # :nodoc:
      def initialize(options, &block)
        @cache_path, @store_options, @cache_layout =
          options.values_at(:cache_path, :store_options, :layout)
      end

      def before(controller)
        return unless controller.pagelet_options.remote

        cache_layout = @cache_layout.respond_to?(:call) ? @cache_layout.call(controller) : @cache_layout

        path_options = if @cache_path.is_a?(Proc)
          controller.instance_exec(controller, &@cache_path)
        elsif @cache_path.respond_to?(:call)
          @cache_path.call(controller)
        else
          @cache_path
        end

        cache_path = ActionController::Caching::Actions::ActionCachePath.new(controller, path_options || {})

        body = controller.read_fragment(cache_path.path, @store_options)

        if body
          layout_opt = cache_layout ? 'layouts/pagelets/container' : true
          body = controller.render_to_string(text: body, layout: layout_opt)

          controller.response_body = body
          controller.content_type = Mime[cache_path.extension || :html]
        end
      end
    end
  end

  module Options
    extend ActiveSupport::Concern

    included do
      include Shared

      helper_method :pagelet_options
    end

    def pagelet_options *args
      set_pagelet_options *args

      opts = self.class.pagelet_options
      class_default_opts = opts.fetch('default', {})
      class_action_opts = opts.fetch(action_name, {})

      instance_default_opts = @pagelet_options.fetch('default', {})
      instance_action_opts = @pagelet_options.fetch(action_name, {})

      result = {}.with_indifferent_access
        .deep_merge!(class_default_opts)
        .deep_merge!(class_action_opts)
        .deep_merge!(instance_default_opts)
        .deep_merge!(instance_action_opts)

      OpenStruct.new result
    end

    module Shared
      def set_pagelet_options *args
        opts = args.extract_options!
        actions = args
        actions << 'default' if actions.blank?

        @pagelet_options ||= {}.with_indifferent_access

        if opts.any?
          actions.each do |action|
            @pagelet_options.deep_merge! action => opts
          end
        end
        @pagelet_options
      end
    end

    module ClassMethods
      include Shared

      def pagelet_options *args
        set_pagelet_options *args

        if superclass && superclass.instance_variable_defined?(:@pagelet_options)
          parent = superclass.instance_variable_get :@pagelet_options
          parent.merge(@pagelet_options)
        else
          @pagelet_options
        end
      end

      def inherited subklass
        existing = subklass.ancestors.reverse.
          reduce({}.with_indifferent_access) do |memo, ancestor|

          if ancestor.instance_variable_defined?(:@pagelet_options)
            memo.deep_merge! ancestor.instance_variable_get :@pagelet_options
          end
          memo
        end

        subklass.instance_variable_set(:@pagelet_options, existing)

        super
      end
    end

  end

  module Routes
    extend ActiveSupport::Concern

    module ClassMethods
      # Define routes inline in controller
      #
      #     pagelet_routes do
      #       resources :users
      #     end
      #
      def pagelet_routes &block
        @pagelet_routes << block
      end

      # Define inline single route for the following method.
      # It automatically adds :controller and :action names to the route
      #
      #     class Pagelets::Examples::ExamplesController
      #       pageletlet_route :get, ''
      #       def bingo
      #       end
      #     end
      #
      # will generate routes
      #   Helper:            pagelets_examples_path
      #   HTTP Verb:         GET
      #   Path:              /pagelets/examples(.:format)
      #   Controller#Action: pagelets/examples/examples#bingo
      #
      def pagelet_route *args
        @pagelet_route << args
      end

      def method_added method_name
        return unless @pagelet_route
        @pagelet_route.each do |args|
          options = args.extract_options!
          options[:controller] ||= self.controller_name
          options[:action] ||= method_name

          @pagelet_routes << Proc.new do
            scope path: options[:controller], as: options[:controller] do
              self.send *args, options
            end
          end
        end

        @pagelet_route = []
        super
      end

      def load_pagelet_routes! context
        @pagelet_routes.each do |proc|
          context.instance_eval &proc
        end
      end

      def inherited subklass
        subklass.instance_variable_set(:@pagelet_routes, [])
        subklass.instance_variable_set(:@pagelet_route, [])
        super
      end
    end
  end

end
