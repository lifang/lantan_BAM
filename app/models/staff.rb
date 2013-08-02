#encoding: utf-8
require 'fileutils'
class Staff < ActiveRecord::Base
  include ApplicationHelper
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
  has_many :material_losses
  belongs_to :store

  
  validates :phone, :uniqueness => { :message => "联系方式已经存在!", :scope => :status}, :if => :staff_not_deleted?
  validates :username, :uniqueness => { :message => "用户名已经存在!", :scope => :status}, :if => :staff_not_deleted?
  #门店员工职务
  S_COMPANY = {:BOSS=>0,:CHIC=>2,:FRONT=>3,:TECHNICIAN=>1,:OTHER=>4} #0 老板 2 店长 3接待 1 技师 4其他
  N_COMPANY = {1=>"技师",3=>"接待",0=>"老板",2=>"店长",4=>"其他"}
  LEVELS = {0=>"高级",1=>"中级",2=>"初级"}  #技师等级
  #总部员工职务

  STATUS = {:normal => 0, :afl => 1, :vacation => 2, :resigned => 3, :deleted => 4}
  VALID_STATUS = [STATUS[:normal], STATUS[:afl], STATUS[:vacation]]
  STATUS_NAME = {0 => "在职", 1 => "请假", 2 => "休假", 3 => "离职", 4 => "删除"}
  scope :normal, where(:status => STATUS[:normal])
  scope :valid, where(:status => VALID_STATUS)
  scope :not_deleted, where("status != #{STATUS[:deleted]}")

  S_HEAD = {:BOSS=>0,:MANAGER =>2,:NORMAL=>1} #0老板 2 店长 1员工
  N_HEAD = {1=>"员工",0=>"老板", 2=>"店长"}
  WORKING_STATS = {:FORMAL => 1, :PROBATION => 0}   #在职状态 0试用 1正式
  S_WORKING_STATS = {1 => "正式", 0 => "实习"}
  IS_DEDUCT = {:YES => 1, :NO =>0} #是否参加提成，1是 0否
  S_IS_DEDUCT = {1 => "是", 0 => "否"}
  #教育程度
  N_EDUCATION = {0 => "研究生", 1 => "本科", 2 => "专科", 3 => "高中", 4 => "初中",
    5 => "小学", 6 => "无"}
  S_EDUCATION = {:GRADUATE => 0,  :UNIVERSITY => 1, :COLLEGE => 2, :SENIOR => 3, :JUNIOR => 4, :PRIMARY => 5, :NONE => 6}

  #员工性别
  N_SEX = {0 => "男", 1 => "女"}

  #分页页数
  PerPage = 10

  def staff_not_deleted?
    status != STATUS[:deleted]
  end

  attr_accessor :password
  #validates :password, :allow_nil => true, :length=>{:within=>6..20} #:confirmation=>true

  after_create :send_message
  after_update :insert_staff_gr_record

  def insert_staff_gr_record
     if (self.level_changed? || self.base_salary_changed? || self.deduct_at_changed? || self.deduct_end_changed? || self.deduct_percent_changed? || self.working_stats_changed?)
       StaffGrRecord.create(:staff_id => self.id, :base_salary => self.base_salary,
                :deduct_at => self.deduct_at, :deduct_end => self.deduct_end,
                :deduct_percent => self.deduct_percent, :working_stats => self.working_stats,
                :level => self.level)
     end
  end

  def has_password?(submitted_password)
		encrypted_password == encrypt(submitted_password)
	end

  def encrypt_password
    self.encrypted_password=encrypt(password)
  end

  def operate_picture(photo,original_filename, status)
    store_id = self.store.id
    FileUtils.remove_dir "#{File.expand_path(Rails.root)}/public/uploads/#{store_id}/#{self.id}" if status.eql?("update") && FileTest.directory?("#{File.expand_path(Rails.root)}/public/uploads/#{store_id}/#{self.id}")
    FileUtils.mkdir_p "#{File.expand_path(Rails.root)}/public/uploads/#{store_id}/#{self.id}"
    File.new(Rails.root.join('public', "uploads", "#{store_id}", "#{self.id}", original_filename), 'a+')
    File.open(Rails.root.join('public', "uploads", "#{store_id}", "#{self.id}", original_filename), 'wb') do |file|
      file.write(photo.read)
    end
    file_path = "#{File.expand_path(Rails.root)}/public/uploads/#{store_id}/#{self.id}/#{original_filename}"
    img = MiniMagick::Image.open file_path,"rb"

    Constant::STAFF_PICSIZE.each do |size|
      resize = size > img["width"] ? img["width"] : size
      new_file = file_path.split(".")[0]+"_#{resize}."+file_path.split(".").reverse[0]
      resize_file_name = original_filename.split(".")[0]+"_#{resize}."+original_filename.split(".").reverse[0]
      self.update_attribute(:photo, "/uploads/#{store_id}/#{self.id}/#{resize_file_name}")
      img.run_command("convert #{file_path}  -resize #{resize}x#{resize} #{new_file}")
    end
  end

  def self.update_staff_working_stats
    Staff.where("working_stats = 0").each do |staff|
      diff_day = (Time.now - staff.created_at).to_i / (24 * 60 * 60)
      if diff_day >= staff.probation_days
        staff.update_attribute(:working_stats, 1)
      end
    end
  end

  def send_message
    if self.store
      content = "#{self.name}，您已经被添加为（#{self.store.name}）的员工，您登录门店后台管理系统的的账号为：#{self.username}，密码为：#{self.username}，修改密码请登录 #{Constant::SERVER_PATH}"
      MessageRecord.transaction do
        message_record = MessageRecord.create(:store_id => self.store_id, :content => content,
          :status => MessageRecord::STATUS[:SENDED], :send_at => Time.now)
        SendMessage.create(:message_record_id => message_record.id, :customer_id => self.id,
          :content => content, :phone => self.phone,
          :send_at => Time.now, :status => MessageRecord::STATUS[:SENDED])
        begin
          message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{self.phone}&Content=#{content}&Exno=0"
          create_get_http(Constant::MESSAGE_URL, message_route)
        rescue
          notice = "短信通道忙碌，请稍后重试。"
        end
        notice = "短信发送成功，账户信息已经发送到手机中。"
      end
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
      SUM(violation_num) as violation_num_sum,
      SUM(gas_num) as gas_num_sum"
  end

end
