module PageletRails::Concerns::CacheOne
  extend ActiveSupport::Concern

  included do
    pagelet_options cache_defaults: {
      expires_in: 5.seconds
    }
  end

  def send_action *args
    if caching_allowed? && cached?
      return_if_cached
    else
      super
      save_cache
    end
  end

  def save_cache
    content = ''
    response_body.each do |parts|
      content << parts
    end

    defaults = (pagelet_options.cache_defaults || {})
    custom = (pagelet_options.cache || {})

    opts = defaults.deep_merge(custom).with_indifferent_access

    opts = opts.slice(:expires_in).symbolize_keys


    puts opts
    write_fragment(cache_key, content, opts)
  end

  def return_if_cached
    return unless caching_allowed? && cached?

    body = read_fragment cache_key
    body = render_to_string(html: body)

    self.response_body = body
    # self.content_type = Mime[cache_path.extension || :html]
    # self.content_type = Mime[:text]
  end

  def caching_allowed?
    (request.get? || request.head?) && response.status == 200
  end

  def cached?
    fragment_exist?(cache_key)
  end

  def cache_key
    cache_params = pagelet_options.cache_params || {}
    if cache_params.respond_to?(:call)
      cache_params = instance_exec(&cache_params)
    end

    opts = {
      controller: params[:controller],
      action: params[:action],
      id: params[:id],
      format: params[:format],
      xhr: request.xhr?
    }.with_indifferent_access.merge(cache_params.to_unsafe_h)

    result = "pagelets/#{opts.to_param}"
    result
  end

end
