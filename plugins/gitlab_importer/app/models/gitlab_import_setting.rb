class GitlabImportSetting < ActiveRecord::Base
  validates :access_token, presence: true
  validates :project_id, presence: true
  validates :gitlab_project_id, presence: true
end
