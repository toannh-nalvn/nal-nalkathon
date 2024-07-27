class CreateGitlabImportTrackerLabels < ActiveRecord::Migration[6.1]
  def change
    create_table :gitlab_import_tracker_labels do |t|
      t.integer :project_id
      t.integer :tracker_id
      t.string :gitlab_label
    end
  end
end
