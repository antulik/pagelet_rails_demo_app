class TabsController < ApplicationController

  # prepend_before_action do
  #   binding.pry
  #   true
  # end

  def show
    # sleep rand(2) + 1

    render params[:id]
  end

end
