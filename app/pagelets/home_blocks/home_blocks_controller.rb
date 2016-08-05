class HomeBlocks::HomeBlocksController < ::PageletController

  pagelet_resources only: :show

  def show
    # sleep 1
    render params[:id]
  end
end
