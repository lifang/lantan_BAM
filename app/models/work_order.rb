#encoding: utf-8
class WorkOrder < ActiveRecord::Base
  belongs_to :station
  belongs_to :order
  belongs_to :store
  STATUS = {0=>"等待服务中",1=>"服务中",2=>"等待付款",3=>"已完成", 4 => "已取消", 5 => "已终止"}
  STAT = {:WAIT =>0,:SERVICING=>1,:WAIT_PAY=>2,:COMPLETE =>3, :CANCELED => 4, :END => 5}

  def self.update_work_order(parms)
    begin
      message = "fail"
      current_day,store,num = Time.now.strftime("%Y%m%d"),Store.find_by_code(parms[:shop]),parms[:id].to_i
      if store
        equipment_info = EquipmentInfo.where("current_day = #{current_day.to_i} and station_id=#{parms[:work].to_i}
                       and store_id=#{store.id}").first
        station = Station.where(:id=>parms[:work].to_i).where(:store_id=>store.id).first
        if station && station.is_has_controller && (equipment_info.nil? || num != equipment_info.num )
          if parms[:name8] == "1" || parms[:name9] == "1"
            station.update_attribute(:status, Station::STAT[:WRONG])
          else
            station.update_attribute(:status, Station::STAT[:NORMAL]) if station.status == Station::STAT[:WRONG]
            work_order = WorkOrder.where("status = #{WorkOrder::STAT[:SERVICING]} and station_id = #{station.id} and
                         current_day = #{current_day} and store_id = #{station.store_id}").first
            if work_order
              work_order.arrange_station(parms[:name2],parms[:name3])
              message = "ok"
              if equipment_info.nil?
                EquipmentInfo.create(:current_day => current_day.to_i, :num =>num,:store_id=>store.id,:station_id=>station.id)
              else
                equipment_info.update_attribute(:num,num)
              end
            end
          end
        end
      end
    rescue
      message = "fail"
    end
    return message
  end

  def arrange_station(gas_num=nil,water_num=nil,stop=false)
    current_time = Time.now
    #把完成的单的状态置为等待付款
    order = self.order
    unless stop
      unless self.status ==  WorkOrder::STAT[:CANCELED]
        runtime = sprintf('%.2f',(current_time - self.started_at)/60).to_f
        status = (order.status == Order::STATUS[:BEEN_PAYMENT] || order.status == Order::STATUS[:FINISHED]) ? WorkOrder::STAT[:COMPLETE] : WorkOrder::STAT[:WAIT_PAY]
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
      order.update_attribute(:status, Order::STATUS[:WAIT_PAYMENT]) if order && order.status != Order::STATUS[:BEEN_PAYMENT] && order.status != Order::STATUS[:FINISHED]
    end

    #排下一个单
    next_work_order = WorkOrder.where("status = #{WorkOrder::STAT[:WAIT]}").
      where(:station_id => self.station_id).
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
      next_order.update_attribute(:status, Order::STATUS[:SERVICING]) if next_order && next_order.status != Order::STATUS[:BEEN_PAYMENT] && next_order.status != Order::STATUS[:FINISHED]
      message = "has_next_work_order"
    else
      #按照created_at时间来排单
      #正在施工中的订单
      orders = Order.includes(:work_orders).where("work_orders.status = #{WorkOrder::STAT[:SERVICING]}").
        where("work_orders.current_day = #{Time.now.strftime("%Y%m%d")}").
        where("work_orders.store_id = #{self.store_id}")

      car_num_id_sql = orders.length == 0 ? '1=1' : "orders.car_num_id not in (?)"

      products = Product.includes(:station_service_relations => :station).
        where(:stations=>{:id => self.station_id}).
        where("products.is_service = #{Product::PROD_TYPES[:SERVICE]}").map(&:id)
      #qualified_station_arr = Station.return_station_arr(products, self.store_id)[0]
      another_work_orders = WorkOrder.joins(:order => {:order_prod_relations => :product}).
        where("work_orders.status = #{WorkOrder::STAT[:WAIT]}").
        where("work_orders.station_id is null").
        where("work_orders.store_id = #{self.store_id}").
        # where("products.is_service = #{Product::PROD_TYPES[:SERVICE]}").
      # where("stations.id in (?)",qualified_station_arr ).
      # where("products.id in (?)",products.length == 0 ? [] : products.map(&:id)).
      where("work_orders.current_day = #{self.current_day}").
        where(car_num_id_sql,orders.map(&:car_num_id)).
        readonly(false).order("work_orders.created_at asc")

      if_wo_set_station = false
      same_car_num_id = nil
      another_work_orders.each do |another_work_order|
        #      if another_work_orders.length >= 1
        another_order = another_work_order.order
        order_product_ids = OrderProdRelation.joins(:product).where(:order_id => another_order,
          :products => {:is_service => Product::PROD_TYPES[:SERVICE]}).map(&:product_id)
        if (products & products).sort == order_product_ids.sort
          station_staffs = StationStaffRelation.find_all_by_station_id_and_current_day self.station_id, Time.now.strftime("%Y%m%d").to_i if self.station_id
          if station_staffs
            staff_id_1 = station_staffs[0].staff_id if station_staffs.size > 0
            staff_id_2 = station_staffs[1].staff_id if station_staffs.size > 1
          end
          if if_wo_set_station
            another_work_order.update_attributes(:station_id => self.station_id) if same_car_num_id == another_work_order.order.car_num_id
            another_order.update_attributes(:cons_staff_id_1 =>staff_id_1,:cons_staff_id_2 => staff_id_2 ) if another_order
          else
            ended_at = current_time + another_work_order.cost_time*60
            another_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING],
              :started_at => current_time, :ended_at => ended_at, :station_id => self.station_id)
            same_car_num_id  = another_order.car_num_id
            if_wo_set_station = true
            another_order.update_attributes(:status => Order::STATUS[:SERVICING],:cons_staff_id_1 =>staff_id_1,:cons_staff_id_2 => staff_id_2 ) if another_order && another_order.status != Order::STATUS[:BEEN_PAYMENT] && another_order.status != Order::STATUS[:FINISHED]

          end
        end

      end unless another_work_orders.blank?
      
      #同一个car_num_id，当符合条件的工位为空时，排单
      same_work_orders = WorkOrder.joins(:order).
        where("work_orders.station_id is null").
        where("work_orders.status = #{WorkOrder::STAT[:WAIT]}").
        where("orders.car_num_id = #{order.car_num_id}").
        where("work_orders.store_id = #{self.store_id}").
        where("work_orders.current_day = #{self.current_day}").readonly(false).order("work_orders.created_at asc")
      if same_work_orders.any?

        first_station = nil
        same_work_orders.each_with_index do |same_work_order, index|
          product_ids = same_work_order.order.order_prod_relations.map(&:product_id)
          infos = Station.return_station_arr(product_ids, same_work_order.store_id)

          station_arr = infos[0]
          wkor_times = WorkOrder.where(:station_id => station_arr, :current_day => Time.now.strftime("%Y%m%d"),
            :store_id =>self.store_id, :status => [WorkOrder::STAT[:WAIT], WorkOrder::STAT[:SERVICING]]).map(&:station_id)
        
          if station_arr.any? and (wkor_times.blank? or wkor_times.length < station_arr.length)
            leave_station = (station_arr - wkor_times)[0]
            station_staffs = StationStaffRelation.find_all_by_station_id_and_current_day leave_station.id, Time.now.strftime("%Y%m%d").to_i if leave_station.id
            if station_staffs
              staff_id_1 = station_staffs[0].staff_id if station_staffs.size > 0
              staff_id_2 = station_staffs[1].staff_id if station_staffs.size > 1
            end
            if index == 0
              s_ended_at = Time.now + same_work_order.cost_time*60
              first_station = leave_station
              same_work_order.update_attribute(:station_id, leave_station.id)
              same_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING], :station_id => leave_station.id,
                :started_at => Time.now, :ended_at => s_ended_at)
              same_work_order.order.update_attributes(:status => Order::STATUS[:SERVICING],:cons_staff_id_1 =>staff_id_1,:cons_staff_id_2 => staff_id_2) if same_work_orders[0].order && same_work_orders[0].order.status != Order::STATUS[:BEEN_PAYMENT] && same_work_orders[0].order.status != Order::STATUS[:FINISHED]
              WkOrTime.create(:current_day => Time.now.strftime("%Y%m%d").to_i, :station_id => leave_station.id,
                :current_times => s_ended_at.strftime("%Y%m%d%H%M"))
            else
              same_work_order.update_attribute(:station_id, first_station.id) if first_station and station_arr.include?(first_station)
              same_work_order.order.update_attributes(:cons_staff_id_1 =>staff_id_1,:cons_staff_id_2 => staff_id_2) if same_work_order and same_work_order.order
            end
          end
        end
      end
    end
    message
  end
  
end
