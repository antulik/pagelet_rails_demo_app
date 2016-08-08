class TabsController < ApplicationController

  def show
    render params[:id], stream: true
  end

end
