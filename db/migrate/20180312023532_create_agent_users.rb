class CreateAgentUsers < ActiveRecord::Migration
  def change
    create_table :agent_users do |t|
      t.integer :uniq_id
      t.string :name, null: false
      t.string :mobile
      # t.string :address
      t.string :source # 来源
      t.integer :star
      t.integer :parent_id
      t.integer :level, default: 0
      t.integer :balance, default: 0  # 余额，单位是分
      t.integer :earnings, default: 0 # 总收益，单位是分
      # t.integer :ratio_0 # 收益分成比例，如果为空，默认等于代理配置中的分成比例
      # t.integer :ratio_1 # 从下级代理获取的收益分成比例，如果为空，默认等于代理配置中的下级代理分成比例
      t.string :earn_ratio # 收益分配比例配置，格式为：40-30-15这就表示3级分销分配模式，40表示自身获得收益提成比例，30表示获得下级收益提成比例，15表示获得下下级的收益提成比例。如果该值为空，那么收益分成会按代理配置分成比例来考虑
      t.datetime :blocked_at # 禁用该账号的时间
      t.string :note
      t.timestamps null: false
    end
    add_index :agent_users, :uniq_id, unique: true
    add_index :agent_users, :parent_id
    add_index :agent_users, :level
  end
end
