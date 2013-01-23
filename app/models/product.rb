class Product < ActiveRecord::Base
  attr_accessible :base_price, :cost_time, :description, :img_url, :introduction, :is_service, :name, :sale_price, :service_code, :staff_level, :staff_level_1, :status, :store_id, :types
end
