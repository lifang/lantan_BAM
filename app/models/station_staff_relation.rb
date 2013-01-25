#encoding: utf-8
class StationStaffRelation < ActiveRecord::Base
  belongs_to :station
  belongs_to :staff
end
