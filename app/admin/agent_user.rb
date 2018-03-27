ActiveAdmin.register AgentUser do
  # menu parent: 'agent', priority: 2, label: '代理商管理'
  menu label: '代理人管理', priority: 6
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
permit_params :name, :mobile, :level, :source, :star, :earn_ratio, :parent_aid, :note
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end

index do
  selectable_column
  column :uniq_id, sortable: false
  column :name, sortable: false
  column '来源', :source, sortable: false
  
  column :level do |o|
    AgentUser::AGENT_LEVELs[o.level]
  end
  column :earnings do |o|
    o.format_money(o.earnings)
  end
  
  column :balance do |o|
    o.format_money(o.balance)
  end
  
  column :earn_ratio, sortable: false do |o|
    o.format_earn_ratio
  end
  
  column :mobile, sortable: false
  column '直接上级代理商', sortable: false do |o|
    o.parent_id.blank? ? '' : link_to(o.parent.name, [:admin, o.parent])
  end
  column :created_at
  
  actions
end

form do |f|
  f.semantic_errors
  f.inputs '基本信息' do
    f.input :name, placeholder: '名字'
    f.input :mobile, placeholder: '11位手机号'
    f.input :source, label: '来源', placeholder: '某某学校或者社会'
    f.input :level, placeholder: '设置代理级别，一级代理填0，二级代理填1，依次类推；如果不填默认创建1级代理'
    f.input :parent_aid, as: :number, label: '直接上级代理ID', placeholder: '上级代理ID'
    f.input :earn_ratio, placeholder: '40-15-5（如果不填，默认为代理配置里面设置的全局收益提成）', hint: '填入的值格式为：40-15-5，分别表示自己销售的提成比例为40%，下级销售我获得提成比例为15%，下下级销售我获得提成比例为5%；如果只支持两级分销，那么配置格式为：40-15；如果支持3级分销，那么格式为：40-15-5；依次类推。如果不填，默认为代理配置的值'
    f.input :star, label: '活跃程度', placeholder: '输入一个大于0的整数来表示'
    f.input :note, as: :text
  end
  
  actions
  
end

end
