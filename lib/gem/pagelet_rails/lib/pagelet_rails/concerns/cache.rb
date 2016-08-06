module PageletRails::Concerns::Cache
  extend ActiveSupport::Concern

  module ClassMethods
    def check_cached_version(*actions)
      return unless cache_configured?

      options = actions.extract_options!
      options[:layout] = true unless options.key?(:layout)
      filter_options = options.extract!(:if, :unless).merge(only: actions)
      cache_options = options.extract!(:layout, :cache_path).merge(store_options: options)

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
          opts.except! 'original_pagelet_options'
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
