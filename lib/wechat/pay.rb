require 'rest-client'
module Wechat
  class Pay
    # 统一下单
    def self.unified_order(order, ip)
      return false if order.blank?
      
      total_fee = SiteConfig.wx_pay_debug == 'true' ? '1' : "#{order.money * 100}"
      params = {
        appid: SiteConfig.wx_app_id,
        mch_id: SiteConfig.wx_mch_id,
        device_info: 'WEB',
        nonce_str: SecureRandom.hex(16),
        body: "账号充值",
        out_trade_no: order.uniq_id,
        total_fee: total_fee,
        spbill_create_ip: ip,
        notify_url: SiteConfig.wx_pay_notify_url,
        trade_type: 'JSAPI',
        openid: order.user.wechat_profile.try(:openid) || '',
        attach: '支付订单'
      }
      
      sign = sign_params(params)
      params[:sign] = sign
      
      xml = params.to_xml(root: 'xml', skip_instruct: true, dasherize: false)
      result = RestClient.post 'https://api.mch.weixin.qq.com/pay/unifiedorder', xml, { :content_type => :xml }
      # puts result
      pay_result = Hash.from_xml(result)['xml']
      # puts pay_result
      return pay_result
    end
    
    # 发现金红包
    def self.send_redbag(billno, send_name, to_user, money, wishing, act_name, remark, scene_id)
      return if billno.blank? or send_name.blank? or to_user.blank? or money.blank?
      
      # puts '真正开始发现金红包...'
      
      # puts act_name
      # puts scene_id
      
      # debug_openid = 'oMc3D0qrLikBmC0NB9unmECSx4bU'
      
      params = {
        wxappid: SiteConfig.wx_app_id,
        mch_id: SiteConfig.wx_mch_id,
        mch_billno: billno,
        nonce_str: SecureRandom.hex(16),
        send_name: send_name,
        re_openid: to_user,
        total_amount: (money * 100).to_i,
        total_num: 1,
        wishing: wishing,
        client_ip: "#{SiteConfig.server_ip}",
        act_name: act_name,
        remark: remark,
        scene_id: scene_id || 'PRODUCT_4'
      }
      
      # puts params
      
      sign = sign_params(params)
      params[:sign] = sign
      
      xml = params.to_xml(root: 'xml', skip_instruct: true, dasherize: false)
      
      result = RestClient::Resource.new(
        'https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack',
        :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read("#{SiteConfig.wx_ssl_cert_file}")),
        :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read("#{SiteConfig.wx_ssl_key_file}"), "#{SiteConfig.wx_ssl_key_pass}"),
        :ssl_ca_file      =>  "#{SiteConfig.wx_ssl_ca_cert_file}",
        :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
      ).post(xml,  { :content_type => :xml })
      # result = RestClient.post 'https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack', xml, { :content_type => :xml }
      # puts result
      pay_result = Hash.from_xml(result)['xml']
      
      # puts pay_result
      
      return pay_result
      
    end
    
    # 关闭订单
    def self.close_order(order)
      return false if order.blank?
      
      params = {
        appid: SiteConfig.wx_app_id,
        mch_id: SiteConfig.wx_mch_id,
        out_trade_no: order.uniq_id,
        nonce_str: SecureRandom.hex(16),
      }
      
      sign = sign_params(params)
      params[:sign] = sign
      
      xml = params.to_xml(root: 'xml', skip_instruct: true, dasherize: false)
      RestClient.post 'https://api.mch.weixin.qq.com/pay/closeorder', xml, { :content_type => :xml }
      
    end
    
    # 参数签名
    def self.sign_params(params)
      arr = params.sort
      hash = Hash[*arr.flatten]
      string = hash.delete_if { |k,v| v.blank? }.map { |k,v| "#{k}=#{v}" }.join('&')
      string = string + '&key=' + SiteConfig.wx_pay_api_key
      Digest::MD5.hexdigest(string).upcase
    end
    
    # 通知校验
    def self.notify_verify?(params)
      
      return false if params['appid'] != SiteConfig.wx_app_id
      return false if params['mch_id'] != SiteConfig.wx_mch_id
      
      sign = params['sign']
      params.delete('sign')
      return sign_params(params) == sign      
      
    end
    
    # 生成H5微信支付参数
    def self.generate_jsapi_params(prepay_id)
      params = {
        appId: SiteConfig.wx_app_id,
        timeStamp: Time.now.to_i,
        nonceStr: SecureRandom.hex(16),
        package: "prepay_id=#{prepay_id}",
        signType: "MD5",
      }
      
      sign = sign_params(params)
      params[:paySign] = sign
      params
    end
    
  end
end