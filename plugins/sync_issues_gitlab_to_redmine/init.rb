Redmine::Plugin.register :sync_issues_gitlab_to_redmine do
  name 'Sync Issues Gitlab To Redmine plugin'
  author 'TT3 - Team Crusher'
  description 'The Redmine-GitLab Issue Sync Plugin is a powerful tool designed to seamlessly integrate Redmine with GitLab'
  version '0.0.1'
  url 'http://10.22.0.35:5000/'
  author_url 'http://10.22.0.35:5000/'
  permission :gitlab_polls, { gitlab_polls: [:index, :vote] }, public: true
  menu :project_menu, :gitlab_polls, { controller: 'gitlab_polls', action: 'index' }, caption: 'Gitlab Settings', after: :activity, param: :project_id
end
