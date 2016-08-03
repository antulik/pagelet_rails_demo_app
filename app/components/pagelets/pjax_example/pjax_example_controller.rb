class Pagelets::PjaxExample::PjaxExampleController < Pagelets::BaseController

  pagelet_resources only: :show

  pagelet_options pjax: true

  def show
    # sleep 1
  end

end
