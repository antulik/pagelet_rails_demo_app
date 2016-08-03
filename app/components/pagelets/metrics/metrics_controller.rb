class Pagelets::Metrics::MetricsController < Pagelets::BaseController

  pagelet_resources only: [:index]

  def index
    @total_comments = Comment.count
    @last_comment_at = Comment.last.created_at
  end

end
