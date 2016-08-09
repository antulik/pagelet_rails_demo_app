class PageletProxyController < ::ApplicationController
  include ActionController::Live
  include PageletsHelper

  def show
    @urls = params[:urls]

    response.headers['Content-Type'] = 'text/javascript'

    @urls.each do |url|
      response.stream.write pagelet(url)
      response.stream.write "\n\n//\n\n"
    end
  ensure
    response.stream.close
  end

end
