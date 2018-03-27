class CreateAgentEarnBills < ActiveRecord::Migration
  def change
    create_table :agent_earn_bills do |t|
      t.string :uniq_id
      t.integer :agent_user_id, null: false
      t.integer :money,         null: false
      t.integer :earn_ratio,    null: false
      t.integer :from_agent_user_id
      t.integer :uid

      t.timestamps null: false
    end
    add_index :agent_earn_bills, :uniq_id, unique: true
    add_index :agent_earn_bills, :agent_user_id
    add_index :agent_earn_bills, :from_agent_user_id
    add_index :agent_earn_bills, :uid
  end
end
