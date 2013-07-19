#encoding: utf-8
class WorkOrder < ActiveRecord::Base
  belongs_to :station
  belongs_to :order
  belongs_to :store
  STATUS = {0=>"等待服务中",1=>"服务中",2=>"等待付款",3=>"已完成", 4 => "已取消"}
  STAT = {:WAIT =>0,:SERVICING=>1,:WAIT_PAY=>2,:COMPLETE =>3, :CANCELED => 4}

  def self.update_work_order
    current_time = Time.now
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
              work_order = WorkOrder.where("status = #{WorkOrder::STAT[:SERVICING]} and station_id = #{station.id} and current_day = #{current_day} and store_id = #{station.store_id}").first
              started_at_sql = work_order.nil? ? "1=1" : "started_at >= '#{work_order.started_at}'"
              next_work_order = WorkOrder.where("status = #{WorkOrder::STAT[:WAIT]} and station_id = #{station.id} and current_day = #{current_day} and store_id = #{station.store_id}").where(started_at_sql).order("started_at asc").first
              if work_order
                runtime = sprintf('%.2f',(current_time - work_order.started_at)/60).to_f
                order = work_order.order
                status = order.status == Order::STATUS[:BEEN_PAYMENT] ? WorkOrder::STAT[:COMPLETE] : WorkOrder::STAT[:WAIT_PAY]
                work_order.update_attributes(:status => status,
                  :water_num => data_arr[3], :gas_num => data_arr[4], :runtime => runtime)
                order = work_order.order
                order.update_attribute(:status, Order::STATUS[:WAIT_PAYMENT]) if order && order.status != Order::STATUS[:BEEN_PAYMENT]
              end
              if next_work_order
                next_work_order.update_attribute(:status, WorkOrder::STAT[:SERVICING])
                next_order = next_work_order.order
                next_order.update_attribute(:status, Order::STATUS[:SERVICING]) if next_order && next_order.status != Order::STATUS[:BEEN_PAYMENT]
              end
            end
          end
        end
        if equipment_info.nil?
          EquipmentInfo.create(:current_day => current_day.to_i, :num => file_data_arr.length)
        else
          equipment_info.update_attribute(:num, file_data_arr.length)
        end
      end
    end
  end

  def arrange_station
    current_time = Time.now
    #把完成的单的状态置为等待付款
    unless self.status ==  WorkOrder::STAT[:CANCELED]
      runtime = sprintf('%.2f',(current_time - self.started_at)/60).to_f
      order = self.order
      status = order.status == Order::STATUS[:BEEN_PAYMENT] ? WorkOrder::STAT[:COMPLETE] : WorkOrder::STAT[:WAIT_PAY]
      self.update_attributes(:status => status, :runtime => runtime)
      
      if runtime > self.cost_time
        staffs = [order.try(:cons_staff_id_1), order.try(:cons_staff_id_2)]
        staffs.each do |staff_id|
          ViolationReward.create(:staff_id => staff_id, :types => ViolationReward::TYPES[:VIOLATION],
          :situation => "订单号#{order.code}超时#{runtime - self.cost_time}分钟",
          :status => ViolationReward::STATUS[:NOMAL])
        end
      end
    end
      order.update_attribute(:status, Order::STATUS[:WAIT_PAYMENT]) if order && order.status != Order::STATUS[:BEEN_PAYMENT]

      #排下一个单
      next_work_order = WorkOrder.where("status = #{WorkOrder::STAT[:WAIT]}").
                                  where("station_id = #{self.station_id}").
                                  where("store_id = #{self.store_id}").
                                  where("current_day = #{self.current_day}").first
      if next_work_order
        #同一个人的下单，直接紧接着排单
        ended_at = current_time + next_work_order.cost_time*60
        next_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING],
          :started_at => current_time, :ended_at => ended_at )
        wo_time = WkOrTime.find_by_station_id_and_current_day next_work_order.station_id, ended_at
        wo_time.update_attribute(:wait_num, wo_time.wait_num - 1) if wo_time and wo_time.wait_num
        next_order = next_work_order.order
        next_order.update_attribute(:status, Order::STATUS[:SERVICING]) if next_order && next_order.status != Order::STATUS[:BEEN_PAYMENT]
        message = "has_next_work_order"
      else
        #按照created_at时间来排单
        products = Product.includes(:station_service_relations => :station).
          where("stations.id=#{self.station_id} and products.is_service = #{Product::PROD_TYPES[:SERVICE]}").select("products.id")
        another_work_order = WorkOrder.joins(:order => {:order_prod_relations => :product}).
                            where("work_orders.status = #{WorkOrder::STAT[:WAIT]}").
                            where("work_orders.station_id is null").
                            where("work_orders.store_id = #{self.store_id}").
                            where("products.is_service = #{Product::PROD_TYPES[:SERVICE]}").
                            where("products.id in (?)",products.map(&:id)).
                            where("work_orders.current_day = #{self.current_day}").readonly(false).order("work_orders.created_at asc").first

        if another_work_order
          ended_at = current_time + another_work_order.cost_time*60
          another_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING],
            :started_at => current_time, :ended_at => ended_at, :station_id => self.station_id)
          another_order = another_work_order.order
          another_order.update_attribute(:status, Order::STATUS[:SERVICING]) if another_order && another_order.status != Order::STATUS[:BEEN_PAYMENT]
        else
          message = "no_next_work_order"
        end
      end
      message
  end
  
end
