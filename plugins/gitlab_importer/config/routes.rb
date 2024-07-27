# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'projects/:project_id/gitlab_importer' => 'gitlab_importer#index'
post 'projects/:project_id/gitlab_importer' => 'gitlab_importer#import'
get 'projects/:project_id/gitlab_importer/setting' => 'gitlab_importer#setting'
post 'projects/:project_id/gitlab_importer/setting' => 'gitlab_importer#update_setting'