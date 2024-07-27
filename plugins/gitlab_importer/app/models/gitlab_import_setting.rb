class GitlabImportSetting < ActiveRecord::Base
  validates :access_token, presence: true, length: {minimum: 5, maximum: 50}
  validates :gitlab_project_id, presence: true, numericality: { only_integer: true }
end
