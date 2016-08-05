class Pagelets::PjaxExample::PjaxExampleController < Pagelets::BaseController

  pagelet_resources only: :show

  def show
    # sleep 1
  end

end
