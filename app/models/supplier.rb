#encoding: utf-8
class Supplier < ActiveRecord::Base
  has_many :material_orders
end
