class HomeBlocks::HomeBlocksController < ::PageletController

  pagelet_resources only: :show

  pagelet_options cache_defaults: {
    cache_path: Proc.new { params.permit(:id, :group) }
  }

  before_action do
    height = case params[:id]
    when 'remote_turbolinks'
      151
    when 'remote_true'
      131
    when 'remote_stream'
      151
    else
      nil
    end
    pagelet_options placeholder: {height: height} if height
  end

  def show
    if params[:id] != 'remote_false' && !request.headers["Turbolinks-Referrer"]
      sleep 1
    end

    render params.require(:id)
  end
end
