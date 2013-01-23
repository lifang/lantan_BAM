class Complaint < ActiveRecord::Base
  attr_accessible :customer_id, :is_violation, :order_id, :process_at, :reason, :remark, :staff_id_1, :staff_id_2, :status, :suggstion, :types
end
