#encoding: utf-8
class WorkOrder < ActiveRecord::Base
  belongs_to :station
  belongs_to :order
  belongs_to :store
  STATUS = {0=>"等待服务中",1=>"服务中",2=>"等待付款",3=>"已完成", 4 => "已取消"}
  STAT = {:WAIT =>0,:SERVICING=>1,:WAIT_PAY=>2,:COMPLETE=>3, :CANCELED => 4}

  def self.update_work_order
    current_day = Time.now.strftime("%Y%m%d")
    file_path = Constant::WORK_ORDER_PATH+current_day+".txt"
    if File.exist?(file_path)
      equipment_info = EquipmentInfo.where("current_day = #{current_day.to_i}").first
      num = equipment_info.nil? ? 0 : equipment_info.num
      file = File.read(file_path)
      file_data_arr = file.split("\n")
      if num < file_data_arr.length
        (num..(file_data_arr.length-1)).each do |index|
          data_arr = file_data_arr[index].split(",")
          station = Station.find_by_id(data_arr[2].to_i)
          if station
            if data_arr[6] == "1" || data_arr[7] == "1"
              station.update_attribute(:status, Station::STAT[:WRONG])
            else
              station.update_attribute(:status, Station::STAT[:LACK]) if station.status == Station::STAT[:WRONG]
              work_order = WorkOrder.where("status = #{WorkOrder::STAT[:SERVICING]} and station_id = #{station.id} and current_day = #{current_day}").first
              started_at_sql = work_order.nil? ? "1=1" : "started_at >= '#{work_order.started_at}'"
              next_work_order = WorkOrder.where("status = #{WorkOrder::STAT[:WAIT]} and station_id = #{station.id} and current_day = #{current_day}").where(started_at_sql).order("started_at asc").first
              work_order.update_attributes(:status => WorkOrder::STAT[:COMPLETE],
                :water_num => data_arr[3], :gas_num => data_arr[4]) if work_order
              next_work_order.update_attribute(:status, WorkOrder::STAT[:SERVICING]) if next_work_order
            end
          end
        end
        if equipment_info.nil?
          store = Store.all.first
          EquipmentInfo.create(:current_day => current_day.to_i, :num => file_data_arr.length, :store_id => store.try(:id))
        else
          equipment_info.update_attribute(:num, file_data_arr.length)
        end
      end
    end
  end
  
end
