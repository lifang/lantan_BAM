class PackageCard < ActiveRecord::Base
  attr_accessible :ended_at, :img_url, :name, :price, :started_at, :status, :store_id
end
