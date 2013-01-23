class CPcardRelation < ActiveRecord::Base
  attr_accessible :content, :customer_id, :ended_at, :package_card_id, :status
end
