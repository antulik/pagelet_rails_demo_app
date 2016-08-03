class Pagelets::Comments::CommentsController < Pagelets::BaseController

  pagelet_resources only: [:show, :new, :create, :index]

  def index
    @comments = Comment.all.order(id: :desc)
  end

  def new
    @comment = Comment.new
  end

  def create
    attrs = params.require(:comment).permit(:author_name, :message)
    @comment = Comment.new attrs

    if @comment.save
      render :create, layout: false
    else
      render :create_error, layout: false
    end

  end

  def show
    # sleep 1
    render params[:id]
  end
end
