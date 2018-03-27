class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer :uniq_id
      t.string :title,   null: false
      t.string :company, null: false
      t.text :body,      null: false
      t.string :price,   null: false
      t.date :work_start_date
      t.date :work_end_date
      t.string :work_length # 工作天数或小时数
      t.boolean :opened, default: false
      t.integer :sort, default: 0

      t.timestamps null: false
    end
    add_index :jobs, :uniq_id, unique: true
  end
end
