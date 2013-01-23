class OrderPayType < ActiveRecord::Base
  attr_accessible :order_id, :pay_type, :price
end
