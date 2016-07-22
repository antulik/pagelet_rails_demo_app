class Pagelets::BlockOne::BlockOneController < Pagelets::BaseController

  pagelet_routes do
    resources :block_one
  end

  pagelet_options pjax: false

  def index
    sleep 5
  end
end
