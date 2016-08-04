class Pagelets::Metrics::MetricsController < Pagelets::BaseController

  pagelet_resource only: [:show]

  def show
    @total_comments = Comment.count
    @last_comment_at = Comment.last.try(:created_at)
  end

end
