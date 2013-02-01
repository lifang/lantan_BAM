#encoding: utf-8
class Staff < ActiveRecord::Base
  has_many :staff_role_relations
  has_many :salary_details
  has_many :work_records
  has_many :salaries
  has_many :station_staff_relations
  has_many :train_staff_relations
  has_many :violation_rwards
  has_many :staff_gr_records
  has_many :month_scores
  belongs_to :store
  #门店员工职务
  S_COMPANY = {:BOSS=>0,:CHIC=>2,:FRONT=>3,:TECHNICIAN=>1} #0 老板 2 店长 3接待 1 技师
  N_COMPANY = {0=>"老板",2=>"店长",3=>"接待",1=>"技师"}
  #总部员工职务
  S_HEAD = {:BOSS=>0,:MANAGER=>2,:NORMAL=>1} #0老板 2 部门经理 1员工
  N_HEAD = {0=>"老板", 2=>"部门经理",1=>"员工"}
end
