require 'rest-client'
class GameRecharge < ActiveRecord::Base
  validates :game_id, :uid, :money, :diamond, :agent_uid, :recharge_desc, presence: true
  
  def money_val=(val)
    self.money = (val.to_f * 100).to_i
  end
  
  def money_val
    self.money / 100.0
  end
  
  def recharge!
    au = AgentUser.find_by(id: self.agent_uid)
    return '代理商不存在' if au.blank?
    
    if au.blocked?
      return '代理商账号已经被禁用'
    end
    
    resp = RestClient.get "#{SiteConfig.game_api_server}/Recharge", 
                     { :params => { :user_id => self.uid,
                                    :diamond => self.diamond
                                  } 
                     }
    result = JSON.parse(resp)
    if result['status'].to_i == 0
      self.recharged_at = Time.zone.now
      self.save!
      
      AgentUser.calc_and_save_earnings_for!(au, self.uid, self.money)
      
      return '充值成功'
    else
      return result['msg']
    end
    
  end
  
end
