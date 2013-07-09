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
  TYPES_NAMES = {0 => "汽车清洁用品", 1 => "汽车美容用品", 2 => "汽车装饰产品", 3 => "汽车配件产品",
    4 => "汽车电子产品",5 =>"其他产品",6 => "辅助工具", 7 => "劳动保护"}
  TYPES = { :CLEAN_PROD =>0, :BEAUTY_PROD =>1,:DECORATE_PROD =>2, :ACCESSORY_PROD =>3, :ELEC_PROD =>4,
    :OTHER_PROD => 5, :ASSISTANT_TOOL => 6, :LABOR_PROTECT => 7}
  PRODUCT_TYPE = [TYPES[:CLEAN_PROD], TYPES[:BEAUTY_PROD], TYPES[:DECORATE_PROD],
    TYPES[:ACCESSORY_PROD], TYPES[:ELEC_PROD], TYPES[:OTHER_PROD]]
  MAT_IN_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_in/%s"
  MAT_OUT_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_out/%s"
  MAT_CHECKNUM_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_check/%s"
  IS_IGNORE = {:YES => 1, :NO => 0} #是否忽略库存预警， 1是 0否
  scope :normal, where(:status => STATUS[:NORMAL])
end
