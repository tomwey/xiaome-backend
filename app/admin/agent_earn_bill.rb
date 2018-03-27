ActiveAdmin.register AgentEarnBill do
  # menu parent: 'agent', priority: 3, label: '分销流水'
  
  menu label: '代理流水', priority: 8
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end

actions :index, :show

index do
  selectable_column
  column :uniq_id, sortable: false
  column :money do |o|
    o.format_money(o.money)
  end
  column :earn_ratio do |o|
    "#{o.earn_ratio}%"
  end
  column '收益' do |o|
    o.earn_money
  end
  column '所属代理', sortable: false do |o|
    link_to o.agent_user.try(:uniq_id), [:admin, o.agent_user]
  end
  column '来自代理', sortable: false do |o|
    o.from_agent_user_id.blank? ? '' : link_to(o.from_agent_user.try(:uniq_id), [:admin, o.from_agent_user])
  end
  column :uid
  column :created_at
  
  actions
end

end
