#encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#菜单
Menu.create(:id => 1,:controller => "customers",:name => "客户管理")
Menu.create(:id => 2,:controller => "materials",:name => "库存管理")
Menu.create(:id => 3,:controller => "staffs",:name => "员工管理")
Menu.create(:id => 4,:controller => "datas",:name => "统计管理")
Menu.create(:id => 5,:controller => "stations",:name => "现场管理")
Menu.create(:id => 6,:controller => "sales",:name => "营销管理")
Menu.create(:id => 7,:controller => "base_datas",:name => "基础数据")
#角色
Role.create(:id => 1,:name => "系统管理员")
Role.create(:id => 2,:name => "老板")
Role.create(:id => 3,:name => "店长")
Role.create(:id => 4,:name => "员工")
#门店
Store.create(:id => 1,:name => "杭州西湖路门店", :address => "杭州西湖路", :phone => "",
  :contact => "", :email => "", :position => "", :introduction => "", :img_url => "",
  :opened_at => Time.now, :account => 0, :created_at => Time.now, :updated_at => Time.now,
  :city_id => 1, :status => 1)
#系统管理员
staff = Staff.create(:name => "系统管理员", :type_of_w => 0, :position => 0, :sex => 1, :level => 2, :birthday => Time.now,
  :status => Staff::STATUS[:normal], :store_id => Store.first.id, :username => "admin", :password => "123456")
staff.encrypt_password
staff.save
StaffRoleRelation.create(:role_id => 1, :staff_id => staff.id)

#系统管理员菜单权限
RoleMenuRelation.create(:role_id => 1, :menu_id => 1)
RoleMenuRelation.create(:role_id => 1, :menu_id => 2)
RoleMenuRelation.create(:role_id => 1, :menu_id => 3)
RoleMenuRelation.create(:role_id => 1, :menu_id => 4)
RoleMenuRelation.create(:role_id => 1, :menu_id => 5)
RoleMenuRelation.create(:role_id => 1, :menu_id => 6)
RoleMenuRelation.create(:role_id => 1, :menu_id => 7)

#系统管理员功能权限
RoleModelRelation.create(:role_id => 1, :model_name => 'customers', :num => 511)
RoleModelRelation.create(:role_id => 1, :model_name => 'materials', :num => 8191)
RoleModelRelation.create(:role_id => 1, :model_name => 'staffs', :num => 16383)
RoleModelRelation.create(:role_id => 1, :model_name => 'datas', :num => 31)
RoleModelRelation.create(:role_id => 1, :model_name => 'stations', :num => 3)
RoleModelRelation.create(:role_id => 1, :model_name => 'sales', :num => 4095)
RoleModelRelation.create(:role_id => 1, :model_name => 'base_datas', :num => 1023)
