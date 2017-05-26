class Comments::CommentsController < ::PageletController

  pagelet_resources only: [:show, :new, :create, :index, :destroy]

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
      redirect_to tab_path('comments')
    else
      render :new
    end
  end

  def show
  end

  def destroy
    comment = Comment.find params[:id]

    if comment.destroy
      redirect_to tab_path('comments')
    else
      index
      render :index
    end
  end
end
