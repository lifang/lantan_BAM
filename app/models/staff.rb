#encoding: utf-8
class Staff < ActiveRecord::Base
  has_many :staff_role_relations, :dependent=>:destroy
  has_many :roles, :through => :staff_role_relations, :foreign_key => "role_id"
  has_many :salary_details
  has_many :work_records
  has_many :salaries
  has_many :station_staff_relations
  has_many :train_staff_relations
  has_many :violation_rwards
  has_many :staff_gr_records
  has_many :month_scores
  belongs_to :store

  attr_accessor :password
  validates:password, :allow_nil => true, :length=>{:within=>6..20} #:confirmation=>true

    #门店员工职务
  S_COMPANY = {:boss=>1,:chic=>2,:front=>3,:technician=>4} #1 老板 2 店长 3接待 4 技师
  N_COMPANY = {1=>"老板",2=>"店长",3=>"接待",4=>"技师"}
  #总部员工职务
  S_HEAD = {:boss=>1,:manager=>2,:normal=>3} #1 老板 2 部门经理 3 员工
  N_HEAD = {1=>"老板", 2=>"部门经理",3=>"员工"}

  def has_password?(submitted_password)
		encrypted_password == encrypt(submitted_password)
	end

  def encrypt_password
    self.encrypted_password=encrypt(password)
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

end
