class SvcReturnRecord < ActiveRecord::Base
  attr_accessible :content, :price, :store_id, :target_id, :total_price, :types
end
