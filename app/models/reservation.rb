class Reservation < ActiveRecord::Base
  attr_accessible :car_num_id, :res_time, :status, :store_id
end
