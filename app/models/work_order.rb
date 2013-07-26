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
          if station && station.is_has_controller == Station::IS_CONTROLLER[:YES]
            if data_arr[6] == "1" || data_arr[7] == "1"
              station.update_attribute(:status, Station::STAT[:WRONG])
            else
              station.update_attribute(:status, Station::STAT[:LACK]) if station.status == Station::STAT[:WRONG]
              work_order = WorkOrder.where("status = #{WorkOrder::STAT[:SERVICING]} and station_id = #{station.id} and current_day = #{current_day} and store_id = #{station.store_id}").first
              #              started_at_sql = work_order.nil? ? "1=1" : "started_at >= '#{work_order.started_at}'"
              #              next_work_order = WorkOrder.where("status = #{WorkOrder::STAT[:WAIT]} and station_id = #{station.id} and current_day = #{current_day} and store_id = #{station.store_id}").where(started_at_sql).order("started_at asc").first
              #              if work_order
              #                runtime = sprintf('%.2f',(current_time - work_order.started_at)/60).to_f
              #                order = work_order.order
              #                status = order.status == Order::STATUS[:BEEN_PAYMENT] ? WorkOrder::STAT[:COMPLETE] : WorkOrder::STAT[:WAIT_PAY]
              #                work_order.update_attributes(:status => status,
              #                  :water_num => data_arr[3], :gas_num => data_arr[4], :runtime => runtime)
              #                order = work_order.order
              #                order.update_attribute(:status, Order::STATUS[:WAIT_PAYMENT]) if order && order.status != Order::STATUS[:BEEN_PAYMENT]
              #              end
              #              if next_work_order
              #                next_work_order.update_attribute(:status, WorkOrder::STAT[:SERVICING])
              #                next_order = next_work_order.order
              #                next_order.update_attribute(:status, Order::STATUS[:SERVICING]) if next_order && next_order.status != Order::STATUS[:BEEN_PAYMENT]
              #              end
              work_order.arrange_station(data_arr[4],data_arr[3]) if work_order
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

  def arrange_station(gas_num=nil,water_num=nil)
    current_time = Time.now
    #把完成的单的状态置为等待付款
    unless self.status ==  WorkOrder::STAT[:CANCELED]
      runtime = sprintf('%.2f',(current_time - self.started_at)/60).to_f
      order = self.order
      status = order.status == Order::STATUS[:BEEN_PAYMENT] ? WorkOrder::STAT[:COMPLETE] : WorkOrder::STAT[:WAIT_PAY]
      self.update_attributes(:status => status, :runtime => runtime,:water_num => water_num, :gas_num => gas_num)
    
      if !self.cost_time.nil?
        if runtime > self.cost_time.to_f
          staffs = [order.try(:cons_staff_id_1), order.try(:cons_staff_id_2)]
          staffs.each do |staff_id|
            ViolationReward.create(:staff_id => staff_id, :types => ViolationReward::TYPES[:VIOLATION],
              :situation => "订单号#{order.code}超时#{runtime - self.cost_time}分钟",
              :status => ViolationReward::STATUS[:NOMAL])
          end
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
      #正在施工中的订单
      orders = Order.includes(:work_orders).where("work_orders.status = #{WorkOrder::STAT[:SERVICING]}").
        where("work_orders.current_day = #{Time.now.strftime("%Y%m%d")}").
        where("work_orders.store_id = #{self.store_id}")

      car_num_id_sql = orders.length == 0 ? '1=1' : "orders.car_num_id not in (?)"

      products = Product.includes(:station_service_relations => :station).
        where("stations.id=#{self.station_id} and products.is_service = #{Product::PROD_TYPES[:SERVICE]}").select("products.id")

      another_work_orders = WorkOrder.joins(:order => {:order_prod_relations => :product}).
        where("work_orders.status = #{WorkOrder::STAT[:WAIT]}").
        where("work_orders.station_id is null").
        where("work_orders.store_id = #{self.store_id}").
        where("products.is_service = #{Product::PROD_TYPES[:SERVICE]}").
        where("products.id in (?)",products.length == 0 ? [] : products.map(&:id)).
        where("work_orders.current_day = #{self.current_day}").
        where(car_num_id_sql,orders.map(&:car_num_id)).
        readonly(false).order("work_orders.created_at asc")

      if another_work_orders.length >= 1
        another_work_order = another_work_orders.first
        ended_at = current_time + another_work_order.cost_time*60
        another_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING],
          :started_at => current_time, :ended_at => ended_at, :station_id => self.station_id)
        another_order = another_work_order.order
        another_order.update_attribute(:status, Order::STATUS[:SERVICING]) if another_order && another_order.status != Order::STATUS[:BEEN_PAYMENT]
        if another_work_orders.length >= 2
          another_work_orders.shift
          another_work_orders.each do |w_k|
            if w_k.order && w_k.order.car_num_id == another_order.car_num_id
              w_k.update_attributes(:station_id => self.station_id)
            end
          end
        end
      else
        message = "no_next_work_order"
      end
      #同一个car_num_id，当符合条件的工位为空时，排单
      same_work_orders = WorkOrder.joins(:order).
        where("work_orders.station_id is null").
        where("work_orders.status = #{WorkOrder::STAT[:WAIT]}").
        where("orders.car_num_id = #{order.car_num_id}").
        where("work_orders.store_id = #{self.store_id}").
        where("work_orders.current_day = #{self.current_day}").readonly(false).order("work_orders.created_at asc")
      if same_work_orders.any?
        product_ids = same_work_orders[0].order.order_prod_relations.map(&:product_id)
        infos = Station.return_station_arr(product_ids, same_work_orders[0].store_id)
        station_arr = infos[0]
        wkor_times = WorkOrder.where(:station_id => station_arr, :current_day => Time.now.strftime("%Y%m%d"),
                     :store_id =>self.store_id, :status => [WorkOrder::STAT[:WAIT], WorkOrder::STAT[:SERVICING]]).map(&:station_id)
        if station_arr.any? and (wkor_times.blank? or wkor_times.length < station_arr.length)
          leave_station = (station_arr - wkor_times)[0]
          s_ended_at = Time.now + same_work_orders[0].cost_time*60
          same_work_orders[0].update_attributes(:status => WorkOrder::STAT[:SERVICING], :station_id => leave_station,
            :started_at => Time.now, :ended_at => s_ended_at)
          same_work_orders[0].order.update_attribute(:status, Order::STATUS[:SERVICING]) if same_work_orders[0].order.status != Order::STATUS[:BEEN_PAYMENT]
          WkOrTime.create(:current_day => Time.now.strftime("%Y%m%d").to_i, :station_id => leave_station,
            :current_times => s_ended_at.strftime("%Y%m%d%H%M"))
        end
      end
    end
    message
  end
  
end
