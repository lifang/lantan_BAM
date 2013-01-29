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

  attr_accessor :password
  validates:password, :confirmation=>true,:length=>{:within=>6..20}, :allow_nil => true

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
