#encoding: utf-8
class Material < ActiveRecord::Base
  has_many :prod_mat_relations
  has_many :mat_order_items
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many :prod_mat_relations
  TYPES_NAMES = {1 => "施工耗材",2 => "辅助工具", 3 => "劳动保护", 4 =>"一次性用品", 0=>"产品"}
  TYPES = { :cost_m=>1,:help_tool=>2,:protected_l=>3,:one_use=>4,:product=>0}
end
