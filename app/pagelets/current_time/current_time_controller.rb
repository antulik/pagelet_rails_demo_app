class CurrentTime::CurrentTimeController < ::PageletController

  pagelet_resource only: [:show]

  pagelet_options placeholder: {height: 131}

  def show

  end
end

