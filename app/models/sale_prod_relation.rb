class SaleProdRelation < ActiveRecord::Base
  attr_accessible :prod_num, :product_id, :sale_id
end
