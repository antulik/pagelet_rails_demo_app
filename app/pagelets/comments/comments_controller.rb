class Comments::CommentsController < ::PageletController

  pagelet_resources only: [:show, :new, :create, :index, :destroy]

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
      new
    end

    render :new
  end

  def show
  end

  def destroy
    comment = Comment.find params[:id]

    if comment.destroy
      trigger_change :comments
    end

    index
    render :index
  end
end
