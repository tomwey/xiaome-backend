ActiveAdmin.register SiteConfig do
  menu parent: 'system', priority: 2, label: '站点配置'

  # menu false if current_admin.super_admin?
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  permit_params :key, :value, :description

end
