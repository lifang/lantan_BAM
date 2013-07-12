class StoreChainsRelations < ActiveRecord::Base
  belongs_to :chain
  belongs_to :store
end
