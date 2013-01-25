#encoding: utf-8
class WorkOrder < ActiveRecord::Base
 belongs_to :station
 belongs_to :order
 belongs_to :store
end
