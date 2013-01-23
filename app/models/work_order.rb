class WorkOrder < ActiveRecord::Base
  attr_accessible :current_day, :electricity_num, :ended_at, :order_id, :runtime, :started_at, :station_id, :status, :store_id, :violation_num, :violation_reason, :water_num
end
