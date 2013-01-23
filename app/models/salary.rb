class Salary < ActiveRecord::Base
  attr_accessible :current_month, :deduct_num, :reward_num, :satisfied_perc, :staff_id, :total
end
