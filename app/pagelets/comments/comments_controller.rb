class Comments::CommentsController < ::PageletController

  pagelet_resources only: [:new, :create, :index, :destroy]

  def index
    identified_by :comments
    @comments = Comment.all.order(id: :desc)
  end

  def new
    @comment = Comment.new
  end

  def create
    attrs = params.require(:comment).permit(:author_name, :message)
    @comment = Comment.new attrs

    if @comment.save
      trigger_change :comments
      redirect_to action: :new
    else
      render :new
    end
  end

  def destroy
    comment = Comment.find params[:id]

    if comment.destroy
      trigger_change :comments
    end

    redirect_to action: :index
  end
end
