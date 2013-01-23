class GoalSale < ActiveRecord::Base
  attr_accessible :current_price, :ended_at, :goal_price, :started_at, :store_id, :type_name
end
