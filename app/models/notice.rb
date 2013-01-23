class Notice < ActiveRecord::Base
  attr_accessible :content, :status, :store_id, :target_id, :types
end
