require 'rest-client'
module API
  module V1
    class PayAPI < Grape::API
      resource :pay, desc: '支付相关的接口' do
        desc "获取充值金额列表"
        params do
          requires :token, type: String, desc: '用户Token'
        end
        get :charge_list do
          authenticate!
          
          moneys = CommonConfig.charge_list.split(',')
          
          { code: 0, message: 'ok', data: moneys }
        end # end get charge_list
        
        desc "充值"
        params do
          requires :token, type: String, desc: '用户Token'
          requires :money, type: Integer, desc: '充值金额，单位为元'
        end
        post :charge do
          user = authenticate!
          
          if params[:money].to_i < 10
            return render_error(-3, '充值金额至少为10元')
          end
          
          charge = Charge.create!(money: params[:money], user_id: user.id, ip: client_ip)
          
          @result = Wechat::Pay.unified_order(charge, client_ip)
          if @result and @result['return_code'] == 'SUCCESS' and @result['return_msg'] == 'OK' and @result['result_code'] == 'SUCCESS'
            { code: 0, message: 'ok', data: Wechat::Pay.generate_jsapi_params(@result['prepay_id']) }
            
          else
            Wechat::Pay.close_order(charge)
            render_error(-3, '发起微信支付失败')
          end
          
        end # end post charge
        
        desc "获取提现金额列表"
        params do
          requires :token, type: String, desc: '用户Token'
        end
        get :withdraw_list do
          authenticate!
          
          { code: 0, message: 'ok', data: { fee: SiteConfig.withdraw_fee, items: SiteConfig.withdraw_items.split(',') } }
        end
        
        desc "提现"
        params do
          requires :token, type: String, desc: '用户Token'
          requires :money, type: Integer, desc: '充值金额，单位为元'
          requires :account_no, type: String, desc: '提现账号'
          requires :account_name, type: String, desc: '提现姓名'
          optional :note, type: String, desc: '提现说明'
        end
        post :withdraw do
          user = authenticate!
          
          min_val = SiteConfig.withdraw_items.split(',')[0].to_f
          
          if params[:money].to_f < min_val
            return render_error(8001, "不能小于最小提现金额#{min_val}元")
          end
          
          if params[:money].to_f > user.balance
            return render_error(8001, "提现失败，余额不足")
          end
          
          Withdraw.create!(user_id: user.id, 
                           money: params[:money], 
                           account_no: params[:account_no], 
                           account_name: params[:account_name], 
                           fee: SiteConfig.withdraw_fee,
                           note: params[:note])
          
          # 修改用户的余额                 
          user.balance -= params[:money]
          user.save!
                           
          render_json(user, API::V1::Entities::User)
        end # end post withdraw
      end # end resource
    end
  end
end