#encoding: utf-8
class MaterialOrder < ActiveRecord::Base
  has_many :mat_order_items
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many  :m_order_types
  belongs_to :supplier

  STATUS = {:normal => 0, :cancel => 1}

  def self.make_order
    status = 0

    status
  end

  def self.material_order_code store_id
    store = store_id.to_s
    if store_id < 10
      store =   "00" + store_id.to_s
    elsif store_id < 100
      store =    "0" + store_id.to_s
    end
    store + Time.now.strftime("%Y%m%d%H%M%S")
  end
end
