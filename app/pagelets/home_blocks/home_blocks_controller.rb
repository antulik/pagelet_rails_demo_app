class HomeBlocks::HomeBlocksController < ::PageletController

  pagelet_resources only: :show

  pagelet_options cache_defaults: {
    cache_path: Proc.new { params.permit(:id, :group) }
  }

  def show
    render params[:id]
  end
end
