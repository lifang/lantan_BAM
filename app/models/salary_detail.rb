#encoding: utf-8
class SalaryDetail < ActiveRecord::Base
  belongs_to :staff
  belongs_to  :violation_reward
end
