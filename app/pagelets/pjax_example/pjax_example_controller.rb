class PjaxExample::PjaxExampleController < ::PageletController

  pagelet_resources only: :show

  def show
    # sleep 1
  end

end
