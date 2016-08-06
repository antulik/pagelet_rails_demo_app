class HomeBlocks::HomeBlocksController < ::PageletController

  pagelet_resources only: :show

  def show
    render params[:id]
  end
end
