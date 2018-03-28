class JobTask < ActiveRecord::Base
  belongs_to :job
  belongs_to :agent_user
  
  validates :content, :job_id, :agent_user_id, :money, :money_val, presence: true
  
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
  
  def money_val=(val)
    self.money = (val.to_f * 100).to_i
  end
  
  def money_val
    if self.money.blank?
      return nil
    end
    self.money.to_i / 100.0
  end
  
end
