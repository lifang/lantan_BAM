class MonthScore < ActiveRecord::Base
  attr_accessible :current_month, :is_sys_update, :manage_score, :staff_id, :sys_score
end
