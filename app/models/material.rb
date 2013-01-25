#encoding: utf-8
class Material < ActiveRecord::Base
  has_many :prod_mat_relations
  has_many :mat_order_items
  has_many :mat_out_orders
  has_many  :mat_in_orders
end
