ActiveAdmin.register Job do
# See permitted parameters documentation:

menu label: '兼职项目', priority: 3
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
permit_params :title, :body, :company, :price, :work_start_date, :work_end_date, :work_length, :opened, :sort

index do
  selectable_column
  column 'ID', :uniq_id, sortable: false
  column :title, sortable: false
  column :company, sortable: false
  column :price
  column :work_start_date
  column :work_end_date
  column :work_length
  column :opened, sortable: false
  column '创建时间', :created_at
  
  actions
end


form do |f|
  f.semantic_errors
  f.inputs '基本信息' do
    f.input :title
    f.input :body, as: :text, input_html: { class: 'redactor' }, placeholder: '网页内容，支持图文混排', hint: '网页内容，支持图文混排'
    f.input :company
    f.input :price, placeholder: '200元/天'
    f.input :work_start_date, as: :string, placeholder: '2018-01-12'
    f.input :work_end_date, as: :string, placeholder: '2018-01-12'
    f.input :work_length, placeholder: '例如：21天'
    f.input :opened, as: :boolean
    f.input :sort
    
  end
  
  actions
  
end

end
