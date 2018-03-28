class CreateJobTasks < ActiveRecord::Migration
  def change
    create_table :job_tasks do |t|
      t.integer :uniq_id, index: true, unique: true
      t.references :job, index: true
      t.references :agent_user, index: true
      t.string :content
      t.integer :money, null: false

      t.timestamps null: false
    end
  end
end
