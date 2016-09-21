class GithubStargazers::GithubStargazersController < ::PageletController

  pagelet_resource only: :show

  pagelet_options placeholder: {text: "Loading Stargazers..."}

  pagelet_options expires_in: 5.minutes, cache_path: (Proc.new { params.permit(:repo) })

  def show
    @repo = params[:repo]
    @result = Octokit.stargazers(@repo)

=begin
    [{:login=>"bjeanes",
 :id=>2560,
 :avatar_url=>"https://avatars.githubusercontent.com/u/2560?v=3",
 :gravatar_id=>"",
 :url=>"https://api.github.com/users/bjeanes",
 :html_url=>"https://github.com/bjeanes",
 :followers_url=>"https://api.github.com/users/bjeanes/followers",
 :following_url=>"https://api.github.com/users/bjeanes/following{/other_user}",
 :gists_url=>"https://api.github.com/users/bjeanes/gists{/gist_id}",
 :starred_url=>"https://api.github.com/users/bjeanes/starred{/owner}{/repo}",
 :subscriptions_url=>"https://api.github.com/users/bjeanes/subscriptions",
 :organizations_url=>"https://api.github.com/users/bjeanes/orgs",
 :repos_url=>"https://api.github.com/users/bjeanes/repos",
 :events_url=>"https://api.github.com/users/bjeanes/events{/privacy}",
 :received_events_url=>"https://api.github.com/users/bjeanes/received_events",
 :type=>"User",
 :site_admin=>false}
,]
=end
  end
end



