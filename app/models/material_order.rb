class MaterialOrder < ActiveRecord::Base
  attr_accessible :arrival_at, :carrier, :code, :logistics_code, :price, :remark, :staff_id, :status, :store_id, :supplier_id, :supplier_type
end
