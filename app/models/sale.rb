class Sale < ActiveRecord::Base
  attr_accessible :car_num, :disc_time_types, :disc_types, :discount, :ended_at, :everycar_times, :img_url, :introduction, :name, :started_at, :status, :store_id
end
