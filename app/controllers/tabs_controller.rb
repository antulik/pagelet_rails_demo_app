class TabsController < ApplicationController

  def show
    render params[:id]
  end

end
