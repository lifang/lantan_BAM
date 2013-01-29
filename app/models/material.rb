#encoding: utf-8
class Material < ActiveRecord::Base
  has_many :prod_mat_relations
  has_many :mat_order_items
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many :prod_mat_relations

  STATUS = {:normal => 0, :delete => 1}
  TYPES = [["施工耗材类",0],["劳动保护",1],["工具类",2]]
end
