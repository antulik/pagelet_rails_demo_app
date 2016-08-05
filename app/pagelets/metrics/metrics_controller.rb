class Metrics::MetricsController < ::PageletController

  pagelet_resource only: [:show]

  pagelet_options placeholder: {height: 122 }

  def show
    @total_comments = Comment.count
    @last_comment_at = Comment.last.try(:created_at)
  end

end
