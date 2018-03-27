class AgentUser < ActiveRecord::Base
  validates :name, presence: true
  
  belongs_to :parent, class_name: 'AgentUser', foreign_key: 'parent_id'
  
  AGENT_LEVELs = ['一级', '二级', '三级']
  
  before_create :generate_unique_id
  def generate_unique_id
    begin
      n = rand(10)
      if n == 0
        n = 8
      end
      self.uniq_id = (n.to_s + SecureRandom.random_number.to_s[2..6]).to_i
    end while self.class.exists?(:uniq_id => uniq_id)
  end
  
  def parent_aid=(val)
    self.parent_id = AgentUser.find_by(uniq_id: val).try(:id)
  end
  
  def parent_aid
    AgentUser.find_by(id: self.parent_id).try(:uniq_id)
  end
  
  def format_money(money)
    return '0.00' if money == 0
    money /= 100.00
    '%.2f' % money
  end
  
  def blocked?
    self.blocked_at.present?
  end
  
  def format_earn_ratio
    key = "L#{self.level}"
    ratio = self.earn_ratio.blank? ? AgentConfig.find_by(key: key).try(:value) : self.earn_ratio
    
    if ratio.blank?
      return '--'
    end
    
    arr = ratio.split("-")
    
    temp = []
    arr.each_with_index do |val, index|
      if val.to_i != 0
        temp << "#{AgentUser::AGENT_LEVELs[index]}提成#{val}%"
      end
    end
    temp.join('；')
  end
  
  # 计算并保存一个代理商以及他的所有上级的提成收益
  def self.calc_and_save_earnings_for!(agent_user, uid, money)
    return if money <= 0 or agent_user.blank?
    
    from_au = nil
    au = agent_user
    
    origin_level = agent_user.level
    
    ActiveRecord::Base.transaction do
      while au != nil 
        ratio = 0
        level = au.level
      
        earn_ratio = au.earn_ratio # 40-15-5
        if earn_ratio.blank?
          earn_ratio = AgentConfig.find_by(key: "L#{level}").value # L0 40-15-5, L1 0-30-10, L2 0-0-20
        end
      
        if not earn_ratio.blank?
          arr = earn_ratio.split('-')
          if origin_level < arr.count
            ratio = arr[origin_level].to_i
          end
        end
      
        AgentEarnBill.create!(agent_user_id: au.id, 
                              money: money, 
                              earn_ratio: ratio, 
                              from_agent_user_id: from_au.try(:id), 
                              uid: uid)
                            
        from_au = au
        au = au.parent
      end # end while
    end # end 结束事务
  end
end
