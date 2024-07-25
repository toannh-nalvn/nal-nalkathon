class CreateTt3Configs < ActiveRecord::Migration[6.1]
  def change
    create_table :tt3_configs do |t|
      t.string :tt3_config
      t.string :apiKey
      t.integer :projectId
      t.integer :milestone
      t.integer :type
    end
  end
end
