class CarNum < ActiveRecord::Base
  belongs_to :car_model
  has_one :customer_num_relation
  has_many :orders
end
