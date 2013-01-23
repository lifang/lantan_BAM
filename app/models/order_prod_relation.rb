class OrderProdRelation < ActiveRecord::Base
  attr_accessible :order_id, :price, :pro_num, :product_id
end
