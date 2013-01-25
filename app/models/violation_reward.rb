#encoding: utf-8
class ViolationReward < ActiveRecord::Base
 belongs_to :staff
 has_many :salary_details
 
end
