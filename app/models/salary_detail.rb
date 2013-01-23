class SalaryDetail < ActiveRecord::Base
  attr_accessible :current_day, :deduct_num, :reward_num, :satisfied_perc, :staff_id, :voilation_reward_id
end
