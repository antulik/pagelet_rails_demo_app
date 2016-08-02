class Pagelets::HomeBlocks::HomeBlocksController < Pagelets::BaseController

  pagelet_routes do
    resources :home_blocks
  end

  def show
    sleep 1
    render params[:id]
  end
end
