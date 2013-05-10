#encoding: utf-8
require 'fileutils'
class Staff < ActiveRecord::Base
  has_many :staff_role_relations, :dependent=>:destroy
  has_many :roles, :through => :staff_role_relations, :foreign_key => "role_id"
  has_many :salary_details
  has_many :work_records
  has_many :salaries
  has_many :station_staff_relations
  has_many :stations, :through => :station_staff_relations
  has_many :train_staff_relations
  has_many :violation_rewards
  has_many :staff_gr_records
  has_many :month_scores
  belongs_to :store
  #门店员工职务
  S_COMPANY = {:BOSS=>0,:CHIC=>2,:FRONT=>3,:TECHNICIAN=>1} #0 老板 2 店长 3接待 1 技师
  N_COMPANY = {0=>"老板",2=>"店长",3=>"接待",1=>"技师"}
  LEVELS = {0=>"高级",1=>"中级",2=>"初级"}  #技师等级
  #总部员工职务

  STATUS = {:normal => FALSE, :delete => TRUE}

  scope :normal, where(:status => STATUS[:normal])

  S_HEAD = {:BOSS=>0,:MANAGER=>2,:NORMAL=>1} #0老板 2 部门经理 1员工
  N_HEAD = {0=>"老板", 2=>"部门经理",1=>"员工"}

  #教育程度
  N_EDUCATION = {0 => "研究生", 1 => "本科", 2 => "专科", 3 => "高中", 4 => "初中",
    5 => "小学", 6 => "无"}
  S_EDUCATION = {:GRADUATE => 0,  :UNIVERSITY => 1, :COLLEGE => 2, :SENIOR => 3, :JUNIOR => 4, :PRIMARY => 5, :NONE => 6}

  #员工性别
  N_SEX = {0 => "男", 1 => "女"}

  #分页页数
  PerPage = 10
  

  attr_accessor :password
  #validates :password, :allow_nil => true, :length=>{:within=>6..20} #:confirmation=>true



  def has_password?(submitted_password)
		encrypted_password == encrypt(submitted_password)
	end

  def encrypt_password
    self.encrypted_password=encrypt(password)
  end

  def operate_picture(photo, status)
    store_id = self.store.id
    FileUtils.remove_dir "#{File.expand_path(Rails.root)}/public/uploads/#{store_id}/#{self.id}" if status.eql?("update") && FileTest.directory?("#{File.expand_path(Rails.root)}/public/uploads/#{store_id}/#{self.id}")
    FileUtils.mkdir_p "#{File.expand_path(Rails.root)}/public/uploads/#{store_id}/#{self.id}"
    File.new(Rails.root.join('public', "uploads", "#{store_id}", "#{self.id}", photo.original_filename), 'a+')
    File.open(Rails.root.join('public', "uploads", "#{store_id}", "#{self.id}", photo.original_filename), 'wb') do |file|
      file.write(photo.read)
    end
    file_path = "#{File.expand_path(Rails.root)}/public/uploads/#{store_id}/#{self.id}/#{photo.original_filename}"
    img = MiniMagick::Image.open file_path,"rb"

    Constant::STAFF_PICSIZE.each do |size|
      resize = size > img["width"] ? img["width"] : size
      new_file = file_path.split(".")[0]+"_#{resize}."+file_path.split(".").reverse[0]
      resize_file_name = photo.original_filename.split(".")[0]+"_#{resize}."+photo.original_filename.split(".").reverse[0]
      self.update_attribute(:photo, "/uploads/#{store_id}/#{self.id}/#{resize_file_name}") if status == "create"
      img.run_command("convert #{file_path}  -resize #{resize}x#{resize} #{new_file}")
    end
  end

  private
  def encrypt(string)
    self.salt = make_salt if new_record?
    secure_hash("#{salt}--#{string}")
  end

  def make_salt
    secure_hash("#{Time.new.utc}--#{password}")
  end

  def secure_hash(string)
    Digest::SHA2.hexdigest(string)
  end

  def self.search_work_record_sql
    "current_day,
      SUM(attendance_num) as attendance_num_sum,
      SUM(construct_num) as construct_num_sum,
      SUM(materials_used_num) as materials_used_num_sum,
      SUM(materials_consume_num) as materials_consume_num_sum,
      SUM(water_num) as water_num_sum,
      SUM(complaint_num) as complaint_num_sum,
      SUM(train_num) as train_num_sum,
      SUM(reward_num) as reward_num_sum,
      SUM(violation_num) as violation_num_sum"
  end

end
