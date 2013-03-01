#encoding: utf-8
namespace :init do
  desc "init data"
  task(:init_data => :environment) do
    #roles
    Role.create(:id => 1,:name => "系统管理员")
    Role.create(:id => 2,:name => "老板")
    Role.create(:id => 3,:name => "店长")
    Role.create(:id => 4,:name => "员工")


  end
end