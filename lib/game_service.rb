require 'rest-client'

class GameService
  def self.fetch_data
    resp = RestClient.get "http://#{SiteConfig.game_server_ip}:8010/gsinfo"
    result = JSON.parse(resp)
    # puts result
    result
  end
  
  def self.get_total_player
    resp = RestClient.get "http://#{SiteConfig.game_server_ip}:9010/GetTotal"
    result = JSON.parse(resp)
    # puts result
    result
  end
end