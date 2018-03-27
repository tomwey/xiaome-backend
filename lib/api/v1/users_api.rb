module API
  module V1
    class UsersAPI < Grape::API
      
      helpers API::SharedParams
      
      # 用户账号管理
      resource :account, desc: "注册登录接口" do
        
        desc "用户注册"
        params do
          requires :mobile,   type: String, desc: "用户手机号"
          requires :password, type: String, desc: "密码"
          requires :code,     type: String, desc: "手机验证码"
          optional :invite_code, type: String, desc: "邀请码，每个用户的invite_code"
        end
        post :signup do
          # 手机号检查
          return render_error(1001, '不正确的手机号') unless check_mobile(params[:mobile])
          
          # 是否已经注册检查
          user = User.find_by(mobile: params[:mobile])
          return render_error(1002, "#{params[:mobile]}已经注册") unless user.blank?
          
          # 密码长度检查
          return render_error(1003, "密码太短，至少为6位") unless params[:password].length >= 6
          
          # 检查验证码是否有效
          auth_code = AuthCode.check_code_for(params[:mobile], params[:code])
          return render_error(2004, '验证码无效') if auth_code.blank?
          
          # 注册
          user = User.create!(mobile: params[:mobile], password: params[:password], password_confirmation: params[:password])
          
          # 激活当前验证码
          auth_code.update_attribute(:activated_at, Time.now)
          
          # 绑定邀请
          inviter = User.find_by(nb_code: params[:invite_code])
          if inviter
            inviter.invite(user)
          end
          
          # 返回注册成功的用户
          render_json(user, API::V1::Entities::User)
        end # end post signup
        
        desc "用户登录"
        params do
          requires :mobile,   type: String, desc: "用户手机号，必须"
          requires :password, type: String, desc: "密码，必须"
        end
        post :login do
          # 手机号检测
          return render_error(1001, "不正确的手机号") unless check_mobile(params[:mobile])
          
          # 登录
          user = User.find_by(mobile: params[:mobile])
          return render_error(1004, "用户#{params[:mobile]}未注册") if user.blank?
          
          if user.authenticate(params[:password])
            render_json(user, API::V1::Entities::User)
          else
            render_error(1005, "登录密码不正确")
          end
        end # end post login
        
        desc "创建微信用户"
        params do
          requires :wx_id, type: String, desc: "微信认证ID"
          optional :wx_avatar, type: String, desc: "微信用户头像Url"
          optional :nickname, type: String, desc: '昵称'
          optional :bio, type: String, desc: '简介'
        end
        post :wx_signup do
          user = User.create!(wx_id: params[:wx_id],
                              wx_avatar: params[:wx_avatar],
                              nickname: params[:nickname], 
                              bio: params[:bio])
          render_json(user, API::V1::Entities::User)
        end # end post wx signup
        
        desc "绑定微信"
        params do
          requires :code, type: String, desc: '微信生成的code'
        end
        post :bind do
          code = WechatAuthCode.where('code = ? and actived_at is null', params[:code]).first
          if code.blank?
            return render_error(-1, '不正确的code')
          end
          
          profile = WechatProfile.find_by(openid: code.wx_id)
          if profile.blank? or profile.user.blank?
            return render_error(-1, '无效的微信用户')
          end
          
          code.actived_at = Time.zone.now
          code.save!
          
          render_json(profile.user, API::V1::Entities::UserBase)
        end # end bind
        
      end # end account resource
      
      resource :user, desc: "用户接口" do
        
        # desc "公开的认证接口"
        # params do
        #   requires :mobile,   type: String, desc: "手机号"
        #   requires :password, type: String, desc: "密码"
        #   optional :mac_addr, type: String, desc: "MAC地址"
        # end
        # get :auth do
        #   # 手机号检测
        #   return render_error(1001, "不正确的手机号") unless check_mobile(params[:mobile])
        #
        #   # 登录
        #   user = User.find_by(mobile: params[:mobile])
        #   return render_error(1004, "用户#{params[:mobile]}未注册") if user.blank?
        #
        #   if user.authenticate(params[:password])
        #     user.update_attribute(:mac_addr, params[:mac_addr]) if user.mac_addr.blank?
        #     render_json(user, API::V1::Entities::User)
        #   else
        #     render_error(1005, "登录密码不正确")
        #   end
        # end # end get auth'
        desc "绑定微信"
        params do
          requires :token, type: String, desc: "用户认证Token"
          requires :wx_id, type: String, desc: "微信认证ID"
        end
        post :wx_bind do
          user = authenticate!
          user.wx_id = params[:wx_id]
          user.save!
          
          render_json(user, API::V1::Entities::User)
        end # end post
        
        desc "获取个人资料"
        params do
          requires :token, type: String, desc: "用户认证Token"
        end
        get :me do
          user = authenticate!
          render_json(user, API::V1::Entities::User)
        end # end get me
        
        desc "修改头像"
        params do
          requires :token,  type: String, desc: "用户认证Token, 必须"
          requires :avatar, type: Rack::Multipart::UploadedFile, desc: "用户头像"
        end
        post :update_avatar do
          user = authenticate!
          
          if params[:avatar]
            user.avatar = params[:avatar]
          end
          
          if user.save
            render_json(user, API::V1::Entities::User)
          else
            render_error(1006, user.errors.full_messages.join(","))
          end
        end # end update_avatar
        
        desc "修改昵称"
        params do
          requires :token,    type: String, desc: "用户认证Token, 必须"
          requires :nickname, type: String, desc: "用户昵称"
        end
        post :update_nickname do
          user = authenticate!
          
          if params[:nickname]
            user.nickname = params[:nickname]
          end
          
          if user.save
            render_json(user, API::V1::Entities::User)
          else
            render_error(1006, user.errors.full_messages.join(","))
          end
        end # end update nickname
        
        desc "修改手机号"
        params do
          requires :token,  type: String, desc: "用户认证Token, 必须"
          requires :mobile, type: String, desc: "新手机号，必须"
          requires :code,   type: String, desc: "新手机号收到的验证码"
        end
        post :update_mobile do
          user = authenticate!
          
          # 手机号检测
          return render_error(1001, "不正确的手机号") unless check_mobile(params[:mobile])
          
          # 检查验证码是否有效
          auth_code = AuthCode.check_code_for(params[:mobile], params[:code])
          return render_error(2004, '验证码无效') if auth_code.blank?
          
          user.mobile = params[:mobile]
          if user.save
            # 激活当前验证码
            auth_code.update_attribute(:activated_at, Time.now)
            
            render_json(user, API::V1::Entities::User)
          else
            render_error(1009, '更新手机号失败！')
          end
          
        end # end post
        
        desc "修改密码"
        params do
          # requires :token,    type: String, desc: "用户认证Token, 必须"
          requires :password, type: String, desc: "新的密码，必须"
          requires :code,     type: String, desc: "手机验证码，必须"
          requires :mobile,   type: String, desc: "手机号，必须"
        end
        post :update_password do
          user = User.find_by(mobile: params[:mobile])
          return render_error(1004, '用户还未注册') if user.blank?
          
          # 检查密码长度
          return render_error(1003, '密码太短，至少为6位') if params[:password].length < 6
          
          # 检查验证码是否有效
          auth_code = AuthCode.check_code_for(user.mobile, params[:code])
          return render_error(2004, '验证码无效') if auth_code.blank?
          
          # 更新密码
          user.password = params[:password]
          user.password_confirmation = user.password
          user.save!
          
          # 激活当前验证码
          auth_code.update_attribute(:activated_at, Time.now)
          
          render_json_no_data
        end # end update password
        
        desc "更新支付密码"
        params do
          requires :token,        type: String, desc: "用户认证Token, 必须"
          requires :code,         type: String, desc: "手机验证码，必须"
          requires :pay_password, type: String, desc: "支付密码，必须"
        end
        post :update_pay_password do
          user = authenticate!
          
          # 检查验证码是否有效
          auth_code = AuthCode.check_code_for(user.mobile, params[:code])
          return render_error(2004, '验证码无效') if auth_code.blank?
          
          # 检查密码长度
          return render_error(1003, '密码太短，至少为6位') if params[:pay_password].length < 6
          
          if user.update_pay_password!(params[:pay_password])
            # 激活当前验证码
            auth_code.update_attribute(:activated_at, Time.now)
            
            render_json_no_data
          else
            render_error(3003, "设置支付密码失败")
          end
          
        end # end update pay_password
        
        desc '获取用户的活动收益记录'
        params do
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :event_earns do
          user = authenticate!
          @earns = user.event_earn_logs.order('id desc')
          if params[:page]
            @earns = @earns.paginate page: params[:page], per_page: page_size
            total = @earns.total_entries
          else
            total = @earns.size
          end
          render_json(@earns, API::V1::Entities::EventEarnLog, {}, total)
        end # end get event earns
        
        desc '获取用户的红包收益记录'
        params do
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :hb_earns do
          user = authenticate!
          @earns = user.redbag_earn_logs.joins(:redbag).where(redbags: { use_type: 1 }).order('id desc')
          if params[:page]
            @earns = @earns.paginate page: params[:page], per_page: page_size
            total = @earns.total_entries
          else
            total = @earns.size
          end
          render_json(@earns, API::V1::Entities::RedbagEarnLog, {}, total)
        end # end get event earns
        
        desc '获取用户抽奖记录'
        params do
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :cj_results do
          user = authenticate!
          @results = user.lucky_draw_prize_logs.joins(:lucky_draw).order('id desc')
          if params[:page]
            @results = @results.paginate page: params[:page], per_page: page_size
            total = @results.total_entries
          else
            total = @results.size
          end
          render_json(@results, API::V1::Entities::LuckyDrawPrizeLog, {}, total)
        end # end get event earns
        
        desc "交易明细"
        params do
          requires :token, type: String, desc: '用户TOKEN'
          use :pagination
        end
        get :trades do
          user = authenticate!
          @logs = user.trade_logs.where.not(tradeable_type: 'Hongbao', money: 0.0).order('id desc')
          if params[:page]
            @logs = @logs.paginate page: params[:page], per_page: page_size
            total = @logs.total_entries
          else
            total = @logs.size
          end
          render_json(@logs, API::V1::Entities::TradeLog, {}, total)
        end # end get trades
        
        desc "获取我领取的卡"
        params do
          requires :token, type: String, desc: '用户认证Token'
          use :pagination
        end
        get :cards do
          user = authenticate!
          
          @user_cards = UserCard.includes(:card).where(user_id: user.id).opened.not_used.not_expired.order('id desc')
          if params[:page]
            @user_cards = @user_cards.paginate page: params[:page], per_page: page_size
            @total = @user_cards.total_entries
          else
            @total = @user_cards.size
          end
          
          render_json(@user_cards, API::V1::Entities::UserCard, {}, @total)
        end # end get cards
        
        desc "获取我的发卡历史"
        params do
          requires :token, type: String, desc: '用户认证Token'
        end
        get :card_histories do
          user = authenticate!
          @cards = Card.opened.where(ownerable: user).order('id desc')
          render_json(@cards, API::V1::Entities::Card)
        end # end get card_histories
        
        desc "获取我已经领取的优惠卡总数"
        params do
          requires :token, type: String, desc: '用户认证Token'
        end
        get :card_badges do
          user = authenticate!
          
          count = UserCard.includes(:card).where(user_id: user.id).opened.not_used.not_expired.count
          
          { code: 0, message: 'ok', data: { count: count } }
          # @cards = Card.opened.where(ownerable: user).order('id desc')
          # render_json(@cards, API::V1::Entities::Card)
        end # end get card_badges
        
        desc "获取我的某个卡的具体记录"
        params do
          requires :token, type: String, desc: '用户认证Token'
          requires :type,  type: Integer, desc: '记录类型，0表示获取领取记录，1表示获取使用记录'
          use :pagination
        end
        get '/cards/:id/users' do
          user = authenticate!
          
          @card = Card.where(ownerable: user, uniq_id: params[:id]).first
          if @card.blank?
            return render_error(4004, '不存在的卡')
          end
          
          @user_cards = UserCard.where(card_id: @card.id)
          if params[:type] == 0 # 获取领取记录
            @user_cards = @user_cards.order('id desc')
          elsif params[:type] == 1 # 获取使用记录
            @user_cards = @user_cards.where.not(used_at: nil).order('used_at desc')
          end
          
          if params[:page]
            @user_cards = @user_cards.paginate page: params[:page], per_page: page_size
            total = @user_cards.total_entries
          else
            total = @user_cards.size
          end
          
          render_json(@user_cards, API::V1::Entities::SimpleUserCard, {}, total)
        end # end get cards/:id/users
        
        desc "发起余额抵扣申请"
        params do
          requires :token, type: String, desc: '用户认证Token'
          requires :money, type: Float,  desc: '抵扣金额'
        end
        post :apply_pay do
          user = authenticate!
          
          if params[:money] < 1.0
            return render_error(-1, '至少需要1元')
          end
          
          if params[:money] > user.balance
            return render_error(-2, '余额不足')
          end
          
          user_pay = UserPay.create!(user: user, money: params[:money])
          
          { code: 0, message: 'ok', data: { code: user_pay.uniq_id, pay_url: "#{SiteConfig.app_server}/wx/user_pay_qrcode" } }
        end # end post apply_pay
        
        desc "用户会话操作"
        params do
          requires :token,   type: String, desc: '用户TOKEN'
          optional :sid,     type: String, desc: '会话ID,用于会话结束操作'
          optional :loc,     type: String, desc: '用户当前位置，值格式为：lng,lat'
          optional :network, type: String, desc: '用户当前的网络类型，例如：2g, 3g, 4g, wifi'
          optional :version, type: String, desc: '当前客户端的版本号'
        end
        post '/session/:action' do
          user = authenticate!
          
          unless %w(begin end).include?(params[:action])
            return render_error(-3, '不支持的操作')
          end
          
          if params[:loc]
            loc = "POINT(#{params[:loc].gsub(',', ' ')})"
          else
            loc = nil
          end
          
          hb = nil
          if params[:action] == 'begin'
            # 会话开始
            session = UserSession.create!(user_id: user.id, 
                                          begin_ip: client_ip, 
                                          begin_time: Time.zone.now, 
                                          begin_loc: loc, 
                                          begin_network: params[:network], 
                                          version: params[:version])
            
            # 每天签到一次
            if Checkin.where(user_id: user.id, created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).count == 0
              checkin = Checkin.create!(user_id: user.id, ip: client_ip, location: loc)
              # money = checkin.money
              hb = checkin.redbag
            end
          else
            # 会话结束
            if params[:sid].blank?
              return render_error(-1, '会话ID不能为空')
            end
            
            session = UserSession.where(user_id: user.id, uniq_id: params[:sid]).first
            
            session.end_ip = client_ip
            session.end_time = Time.zone.now
            session.end_loc = loc
            session.end_network = params[:network]
            
            session.save!
          end
          
          if hb
            { code: 0, message: 'ok', data: { sid: session.uniq_id, hb: API::V1::Entities::Redbag.represent(hb) } }
          else
            { code: 0, message: 'ok', data: { sid: session.uniq_id } }
          end
        end # end post session/begin session/end
        
      end # end user resource
      
    end 
  end
end