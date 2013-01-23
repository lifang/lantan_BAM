class StaffGrRecord < ActiveRecord::Base
  attr_accessible :base_salary, :deduct_at, :deduct_end, :deduct_percent, :level, :staff_id
end
