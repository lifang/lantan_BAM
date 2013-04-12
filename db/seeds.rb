#encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#菜单
Menu.create(:id => 1,:controller => "customers",:name => "客户")
Menu.create(:id => 2,:controller => "materials",:name => "库存")
Menu.create(:id => 3,:controller => "staffs",:name => "员工")
Menu.create(:id => 4,:controller => "datas",:name => "统计")
Menu.create(:id => 5,:controller => "stations",:name => "现场")
Menu.create(:id => 6,:controller => "sales",:name => "营销")
#角色
Role.create(:id => 1,:name => "系统管理员")
Role.create(:id => 2,:name => "老板")
Role.create(:id => 3,:name => "店长")
Role.create(:id => 4,:name => "员工")
#门店
store = Store.create(:id => 1, :name => "杭州西湖路门店", :address => "杭州西湖路", :phone => "",
  :contact => "", :email => "", :position => "", :introduction => "", :img_url => "",
  :opened_at => Time.now, :account => 0, :created_at => Time.now, :updated_at => Time.now,
  :city_id => 1, :status => 1)
#系统管理员
staff = Staff.create(:name => "系统管理员", :type_of_w => 0, :position => 0, :sex => 1, :level => 2, :birthday => Time.now,
  :status => Staff::STATUS[:normal], :store_id => store.id, :username => "admin", :password => "123456")
staff.encrypt_password
StaffRoleRelation.create(:role_id => 1, :satff_id => staff.id)

