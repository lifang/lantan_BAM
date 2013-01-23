class Order < ActiveRecord::Base
  attr_accessible :c_pcard_relation_id, :c_svc_relation_id, :car_num_id, :code, :cons_staff_id_1, :cons_staff_id_2, :ended_at, :front_staff_id, :integer, :is_billing, :is_free, :is_pleased, :is_visited, :price, :sale_id, :started_at, :station_id, :status, :types
end
