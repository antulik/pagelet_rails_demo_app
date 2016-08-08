class StreamingController < ApplicationController

  def show
    render :show, stream: true
  end

end
