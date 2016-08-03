class Pagelets::Comments::CommentsController < Pagelets::BaseController

  pagelet_resources only: [:show, :new]

  def new

  end

  def show
    # sleep 1
    render params[:id]
  end
end
