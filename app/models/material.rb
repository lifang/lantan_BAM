#encoding: utf-8
class Material < ActiveRecord::Base
  has_many :prod_mat_relations
  has_many :mat_order_items
  has_many :material_orders, :through => :mat_order_items do 
    def not_all_in
       where("m_status != 3")
    end
  end
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many :prod_mat_relations

  STATUS = {:NORMAL => 0, :DELETE => 1}
  TYPES_NAMES = {1 => "施工耗材",2 => "辅助工具", 3 => "劳动保护", 4 =>"一次性用品", 5=>"产品"}
  TYPES = { :COST_M =>1,:HELP_TOOL =>2,:PROTECTED_L =>3,:ONE_USE =>4,:PRODUCT =>5}
  MAT_IN_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_in/%s"
  MAT_CHECKNUM_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_check/%s"
  IS_IGNORE = {:YES => 1, :NO => 0} #是否忽略库存预警， 1是 0否
  scope :normal, where(:status => STATUS[:NORMAL])
end
