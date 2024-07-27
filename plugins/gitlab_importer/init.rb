Redmine::Plugin.register :gitlab_importer do
  name 'Gitlab Importer plugin'
  author 'Crusher Overthinking'
  description 'Import project data from Gitlab to Redmine'
  version '1.0.0'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  permission :gitlab_importer, {gitlab_importer: [:index, :import]}, :public => false
  menu :admin_menu, :gitlab_importer, { controller: 'settings', action: 'plugin', id: 'gitlab_importer' }, caption: 'Gitlab Importer'
  menu :project_menu, :gitlab_importer, { :controller => 'gitlab_importer', :action => 'index' }, caption: 'Import Gitlab Issues', after: :activity, param: :project_id

  project_module :gitlab_importer do
    permission :gitlab_importer, gitlab_importer: :index
  end
end


