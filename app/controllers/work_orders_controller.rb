#encoding: utf-8
class WorkOrdersController < ApplicationController
  def work_orders_status
      store = Store.find_by_id(params[:store_id]) #查询所有门店记录
      date = Time.now.to_s  #获取当前日期时间
      now_date = (date.slice(0,4) + date.slice(5,2) + date.slice(8,2)).to_i #截取当前年月日转换成int型的数据

      current_info = {} #哈希：一个门店的数据（等待付款、工位信息（工位名称、状态、技师、正在施工车牌、剩余时间、等待施工车牌、剩余时间））
      wait_pay_car_nums = [] #定义数组存放所有待付款车牌
      #查询所有未删除的工位信息
      stations = Station.find_by_sql("select s.id, s.status, s.name
      from stations s where s.status !=#{Station::STAT[:DELETED]} and s.store_id = #{params[:store_id]} order by s.id")

      #查询所有当天的技师信息
      cons_staffs = Station.find_by_sql("select s.id as station_id, staffs.name as staff_name
      from stations s inner join station_staff_relations ssr on s.id = ssr.station_id
      inner join staffs on ssr.staff_id = staffs.id where s.store_id = #{params[:store_id]} and
      ssr.current_day = #{now_date}")

      #查询所有工单对应的车牌号等信息
      work_orders = Station.find_by_sql("select s.id as station_id, TIMESTAMPDIFF(minute,now(),w.ended_at)
      as time_left, c.num as car_num, w.status as work_order_status, w.updated_at as wo_updated_at from stations s inner join
      work_orders w on s.id =  w.station_id inner join orders o on w.order_id = o.id inner join
      car_nums c on o.car_num_id = c.id where s.store_id = #{params[:store_id]} and w.current_day = #{now_date} and
      o.status != #{Order::STATUS[:DELETED]}
      order by w.started_at asc")

      if stations != nil
        stations.each do |station| #遍历所有工位
          if station.status == Station::STAT[:NORMAL]
            #为该工位加入技师信息
            station[:cons_staffs] = []
            #station[:waiting_car_num] = []

            if cons_staffs == nil
              station[:cons_staffs] = nil
            else
              cons_staffs.each do |cons_staff|
                if cons_staff.station_id == station.id
                  station[:cons_staffs] << cons_staff.staff_name
                end
              end
            end
            # 如果该工位下员工为空时，将station[:cons_staffs]设为空值
            if station[:cons_staffs].length == 0
              station[:cons_staffs] = nil
            end

            #加入订单信息
            if work_orders != nil
              work_orders.each do |work_order|
                if work_order.station_id == station.id
                  # STATUS = {0=>"等待服务中",1=>"服务中",2=>"等待付款",3=>"已完成"}
                  # STAT = {:WAIT=>0,:SERVICING=>1,:WAIT_PAY=>2,:COMPLETE=>3}
                  #等待付款车牌号
                  if work_order.work_order_status == WorkOrder::STAT[:WAIT_PAY] || 
                      (work_order.work_order_status == WorkOrder::STAT[:COMPLETE] &&
                        (Time.now - work_order.wo_updated_at)/60 <= 1)
                    wait_pay_car_nums << work_order.car_num
                  end

                  #正在施工的车牌号及剩余时间
                  if work_order.work_order_status == WorkOrder::STAT[:SERVICING]
                    station[:dealing_car_num] = work_order.car_num
                    station[:dealing_time_left] = work_order.time_left
                    if station[:dealing_time_left].to_i  < 0
                      station[:dealing_time_left] = 0
                    end
                  end

                  ##等待施工的车牌号
                  #if work_order.work_order_status == WorkOrder::STAT[:WAIT]
                  #  station[:waiting_car_num] << work_order.car_num
                  #end
                end# if work_order.station_id == station.id 结束标记
              end# work_orders.each do |work_order| 结束标记
              #如果没有正在施工的车辆，则正在施工的车牌、剩余时间为空
              station[:dealing_car_num] = nil unless station[:dealing_car_num]
              station[:dealing_time_left] = nil unless station[:dealing_time_left]
              #station[:waiting_car_num] = nil if station[:waiting_car_num].length == 0

            else  #工位正常，但没有工单时：等待付款、正在施工的车牌、剩余时间、等待施工的车牌均为空
              station[:dealing_time_left] = nil
              station[:dealing_car_num] = nil
              #station[:waiting_car_num] = nil
            end# if work_orders.length != 0 结束标记
          end # if station.status == Station::STAT[:NORMAL] 结束标记
        end # stations.each do |station| 结束标记
      end #if stations.length != 0 结束标记
      current_info[:wait_pay_car_nums] = nil
      current_info[:station_infos] = nil
      if wait_pay_car_nums.length != 0
        current_info[:wait_pay_car_nums] = wait_pay_car_nums
      else
        current_info[:wait_pay_car_nums] = nil
      end
      if stations != nil
        current_info[:station_infos] = stations
      else
        current_info[:station_infos] = nil
      end
      current_info[:no_station_wos] = Order.joins(:work_orders).where("work_orders.current_day =? and work_orders.store_id = ? and work_orders.status != ? and work_orders.station_id is null", now_date, params[:store_id], WorkOrder::STAT[:CANCELED]).map(&:car_num).map(&:num)
      render :json => current_info
  end# work_orders_status 方法结束标记

def login
   staff = Staff.find(:first, :conditions => ["username = ? and status in (?)",params[:user_name], Staff::VALID_STATUS])
    info = ""
    if  staff.nil? or !staff.has_password?(params[:user_password])
      info = "用户名或密码错误"
      status = 2
    elsif staff.store.nil? or staff.store.status != Store::STATUS[:OPENED]
      info = "用户不存在"
      status = 1
    else
      status = 0
      stations_count = Station.where(:store_id => staff.store_id, :status => Station::STAT[:NORMAL]).count
    end
    render :json => {:store_id => staff.present? ? staff.store_id : 0, :status => status, :stations_count => stations_count || 0}
end

end
