class CustomerStoreRelation < ActiveRecord::Base
  belongs_to :customer
  belongs_to :store
end
