#encoding: utf-8
class StoreComplaint < ActiveRecord::Base
  belongs_to :complaint
end
