class GithubLink::GithubLinkController < ::PageletController

  pagelet_resource only: [:show]

  def show
    @files = pagelet_options.files.reduce({}) do |memo, (k, v)|
      memo[k] = "https://github.com/antulik/pagelet/tree/master/#{v}"
      memo
    end
  end

end
