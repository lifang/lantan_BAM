#encoding: utf-8
class CreateMenus < ActiveRecord::Migration
  #菜单表
  def change
    create_table :menus do |t|
      t.string :controller
      t.string :name
    end
    Menu.create(:id => 1,:controller => "customers",:name => "客户")
    Menu.create(:id => 1,:controller => "materials",:name => "库存")
    Menu.create(:id => 1,:controller => "staffs",:name => "员工")
    Menu.create(:id => 1,:controller => "datas",:name => "统计")
    Menu.create(:id => 1,:controller => "stations",:name => "现场")
    Menu.create(:id => 1,:controller => "sales",:name => "营销")

    add_index :menus, :controller
    
  end
  
end
