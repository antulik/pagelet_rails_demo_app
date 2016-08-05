class Pagelets::CurrentTime::CurrentTimeController < Pagelets::BaseController

  pagelet_resource only: [:show]

  def show

    puts pagelet_options

  end
end

