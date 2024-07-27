# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'gitlab_importer' => 'gitlab_importer#index'
post 'gitlab_importer' => 'gitlab_importer#import'
