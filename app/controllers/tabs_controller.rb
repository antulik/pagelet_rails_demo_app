class TabsController < ApplicationController

  def show
    # sleep rand(2) + 1

    render params[:id]
  end

end
