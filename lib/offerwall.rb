require 'openssl'
require 'base64'
require 'erb'

class Offerwall
  
  def self.youmi_req_sign(channel, openid, feedback = '')
    return nil if channel.blank? or openid.blank?
    
    aes = OpenSSL::Cipher::Cipher.new('AES-128-CBC')
    aes.encrypt
    aes.key = channel.app_secret
    iv = aes.random_iv
    aes.iv = iv
    s = Base64.encode64(openid) + '&' + Base64.encode64(feedback)
    cipher = aes.update(s)
    cipher << aes.final
    r = ERB::Util.url_encode(channel.appid + Base64.encode64(iv + cipher).gsub(/\n/, ''))
    return r
  end
  
  def self.youmi_android_resp_sign(server_secret, params)
    # {"cid"=>"868271", "order"=>"YM170905io8dNAc0fb", "app"=>"8c6c635842931ac8", "ad"=>"红包天气", "pkg"=>"com.fenghe.android.weather", "user"=>"oMc3D0uyihKH_5IOtO2ZgQntM69M", "chn"=>"0", "points"=>"37", "price"=>"0", "time"=>"1504618295", "device"=>"863127032206531", "adid"=>"18672", "trade_type"=>"1", "sig"=>"214ac4bd", "controller"=>"offerwall/home", "action"=>"callback"}
    return false if server_secret.blank? or params.blank?
    
    string = server_secret + '||' + params[:order] + '||' + params[:app] + '||' + params[:user] + '||' + params[:chn] + '||' + params[:ad] + '||' + params[:points]
    sig = Digest::MD5.hexdigest(string)
    return sig[12,8] == params[:sig]
  end
  
  def self.youmi_ios_resp_sign(server_secret, params)
    return false if server_secret.blank? or params.blank?
    
    # {"cid"=>"433784", "order"=>"YM170906q8SSPo2i79", "app"=>"e338339c15e4ea26", "ad"=>"hello语音", "adid"=>"23436", "user"=>"oMc3D0qrLikBmC0NB9unmECSx4bU", "chn"=>"0", "points"=>"98", "price"=>"0", "time"=>"1504676209", "device"=>"B4EDCC68-B45B-4753-8847-A59884A57F0F", "storeid"=>"885737901", "sig"=>"1e629ab3", "sign"=>"d74c95e8ddbbe57ecc6cc351e9187990", "controller"=>"offerwall/home", "action"=>"callback"}
    
    sign = params[:sign]
    
    params.delete(:sign)
    
    arr = params.sort
    hash = Hash[*arr.flatten]
    string = hash.delete_if { |k,v| v.blank? }.map { |k,v| "#{k}=#{v}" }.join('')
    string = string + server_secret
    return Digest::MD5.hexdigest(string) == sign
  end
  
end