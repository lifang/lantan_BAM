class WOTime < ActiveRecord::Base
  attr_accessible :current_day, :current_time, :station_id, :wait_num, :worked_num
end
