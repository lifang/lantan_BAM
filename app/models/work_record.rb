class WorkRecord < ActiveRecord::Base
  attr_accessible :attendance_num, :complaint_num, :construct_num, :current_day, :materials_consume_num, :materials_used_num, :train_num, :violation_num, :water_num
end
