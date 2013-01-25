class CarNum < ActiveRecord::Base
  belongs_to :car_model
  has_many :customer_num_relations
  
end
