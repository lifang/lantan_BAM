#encoding: utf-8
class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :name
    end

    Role.create(:id => 1,:name => "系统管理员")
    Role.create(:id => 2,:name => "老板")
    Role.create(:id => 3,:name => "店长")
    Role.create(:id => 4,:name => "员工")
  end
end
