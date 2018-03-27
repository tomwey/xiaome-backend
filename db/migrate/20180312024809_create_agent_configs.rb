class CreateAgentConfigs < ActiveRecord::Migration
  def change
    create_table :agent_configs do |t|
      t.string :key, null: false
      t.string :value, null: false
      t.string :description

      t.timestamps null: false
    end
    add_index :agent_configs, :key, unique: true
  end
end
