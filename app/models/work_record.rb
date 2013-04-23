#encoding: utf-8
class WorkRecord < ActiveRecord::Base
  belongs_to :staff

  def self.update_record
#        WorkRecord.update_record
    station_s =StationStaffRelation.where("current_day=#{Time.now.strftime("%Y%m%d").to_i}").map(&:staff_id)
    Staff.all.each do |staff|
      if station_s.include? staff.id

      else

      end
    end
  end
end
