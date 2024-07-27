class CreateGitlabImportSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :gitlab_import_settings do |t|
      t.integer :project_id
      t.string :access_token
      t.integer :gitlab_project_id
      t.string :issue_parent_label
    end
  end
end
