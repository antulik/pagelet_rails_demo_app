require_dependency 'pagelet_rails'

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
