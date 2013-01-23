class Train < ActiveRecord::Base
  attr_accessible :certificate, :content, :end_at, :start_at
end
