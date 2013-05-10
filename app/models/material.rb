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

  scope :normal, where(:status => STATUS[:NORMAL])
  after_save :strip_material_name

  private

  def strip_material_name
    name = self.name.strip
    self.update_column(:name,name)
  end
end
