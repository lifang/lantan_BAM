class ViolationReward < ActiveRecord::Base
  attr_accessible :mark, :process_types, :situation, :staff_id, :status, :target_id, :types
end
