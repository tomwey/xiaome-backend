ActiveAdmin.register JobTask do
  
  menu label: '代理任务', priority: 4
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
permit_params :content, :job_id, :agent_user_id, :money_val

index do
  selectable_column
  column 'ID', :uniq_id, sortable: false
  column :content, sortable: false
  column '支付金额', :money_val
  column '分配的兼职' do |o|
    link_to o.job.try(:title), [:admin, o.job]
  end
  column '代理人' do |o|
    link_to o.agent_user.try(:name), [:admin, o.agent_user]
  end
  column '创建时间', :created_at
  
  actions
end

form do |f|
  f.semantic_errors
  f.inputs '基本信息' do
    f.input :content, as: :text, placeholder: '描述一下分配给代理的兼职'
    f.input :money_val, as: :number, label: '支付金额', required: true, placeholder: '输入金额，单位元'
    f.input :job_id, as: :select, label: '分配兼职', collection: Job.where(opened: true).map { |job| [job.title, job.id] }, required: true, prompt: '-- 选择一个兼职 --'
    f.input :agent_user_id, as: :select, label: '指定代理人', collection: AgentUser.all.map { |a| [a.name, a.id] }, required: true, prompt: '-- 选择一个代理人 --'
  end
  
  actions
  
end

end
