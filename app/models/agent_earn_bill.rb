class AgentEarnBill < ActiveRecord::Base
  validates :agent_user_id, :money, :earn_ratio, presence: true
  
  belongs_to :agent_user
  belongs_to :from_agent_user, class_name: 'AgentUser', foreign_key: 'from_agent_user_id'
  
  before_create :generate_uniq_id
  def generate_uniq_id
    begin
      self.uniq_id = Time.now.to_s(:number)[2,6] + (Time.now.to_i - Date.today.to_time.to_i).to_s + Time.now.nsec.to_s[0,6]
    end while self.class.exists?(:uniq_id => uniq_id)
  end
  
  def format_money(money)
    return '0.00' if money == 0
    money /= 100.00
    '%.2f' % money
  end
  
  after_create :change_agent_users_earnings
  def change_agent_users_earnings
    if agent_user
      val = BigDecimal.new((money / 100.0).to_s) * BigDecimal.new((earn_ratio / 100.0).to_s)
      val = (val * 100).to_i
      agent_user.earnings += val
      agent_user.balance += val
      agent_user.save!
    end
  end
  
  def earn_money
    val = BigDecimal.new((money / 100.0).to_s) * BigDecimal.new((earn_ratio / 100.0).to_s)
    '%.2f' % val.to_f
  end
  
end
