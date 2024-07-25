# Plugin's routes
get 'gitlab_polls', to: 'gitlab_polls#index'
post 'gitlab_post/:id/vote', to: 'gitlab_polls#vote'
post 'projects/:project_id/post/:id/vote', to: 'gitlab_polls#vote', as: 'vote_poll'