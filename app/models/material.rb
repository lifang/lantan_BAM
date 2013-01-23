class Material < ActiveRecord::Base
  attr_accessible :code, :name, :price, :status, :storage, :store_id, :types
end
