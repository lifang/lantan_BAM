#encoding: utf-8
class Supplier < ActiveRecord::Base
  has_many :material_orders
  has_many :back_good_records
  TYPES = {:head => 0,:branch => 1}
  STATUS = {:normal => 0, :delete => 1}
end
