# Plugin's routes
# get 'gitlab_polls', to: 'gitlab_polls#index'
get '/projects/:project_id/gitlab_polls', :to => "gitlab_polls#index"
post 'gitlab_post/:id/vote', to: 'gitlab_polls#vote'
post 'projects/:project_id/post/:id/vote', to: 'gitlab_polls#vote', as: 'vote_poll'
get 'tt3_configs', to: 'tt3_configs#index'
get '/projects/:project_id/gitlab_polls/show', :to => "gitlab_polls#show"
