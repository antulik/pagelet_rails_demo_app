module PageletRails::Concerns::CacheTwo
  extend ActiveSupport::Concern

  included do
    include ActionController::Caching::Actions

    pagelet_options cache_defaults: {
      expires_in: 5.seconds,
      cache_path: {}
    }

    around_action :pagelet_cache
  end

  def pagelet_cache &block
    cache_enabled = pagelet_options.cache || pagelet_options.cache_path || pagelet_options.expires_in

    cache_enabled = false if pagelet_options.remote

    if !cache_enabled
      return yield
    end

    cache_defaults = (pagelet_options.cache_defaults || {}).to_h.symbolize_keys
    store_options = cache_defaults.except(:cache_path)
    store_options[:expires_in] = pagelet_options.expires_in if pagelet_options.expires_in

    cache_path = pagelet_options.cache_path || cache_defaults[:cache_path]

    cache_options = {
      layout: false,
      store_options: store_options,
      cache_path: cache_path
    }

    filter = ActionController::Caching::Actions::ActionCacheFilter.new(cache_options)

    filter.around(self, &block)
  end

end
