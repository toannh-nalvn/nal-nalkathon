class GitlabImportSetting < ActiveRecord::Base
  validates :access_token, presence: true, allow_blank: false
  validates :project_id, presence: true, allow_blank: false
  validates :gitlab_project_id, presence: true, allow_blank: false
end
