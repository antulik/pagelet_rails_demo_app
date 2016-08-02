class Pagelets::PjaxExample::PjaxExampleController < Pagelets::BaseController

  pagelet_routes do
    resources :pjax_example
  end

  pagelet_options pjax: true

  def show
    sleep 1
  end

end
