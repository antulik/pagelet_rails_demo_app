class Pagelets::HomeBlocks::HomeBlocksController < Pagelets::BaseController

  pagelet_resources only: :show

  def show
    # sleep 1
    render params[:id]
  end
end
