#encoding: utf-8
class WorkOrdersController < ApplicationController
  def work_orders_status
    #store = Store.find_by_id(params[:store_id])
    now_date = Time.now.strftime("%Y%m%d").to_i   #获取当前日期时间
    current_info = {} #哈希：一个门店的数据（等待付款、工位信息（工位名称、状态、技师、正在施工车牌、剩余时间、等待施工车牌、剩余时间））
    wait_pay_car_nums,normal_station = [],[] #定义数组存放所有待付款车牌
    stations = Station.where(:store_id=>params[:store_id]).can_show.select("name,status,id").order("id")    #查询所有未删除的工位信息
    cons_staffs = Station.joins(:station_staff_relations=>:staff).select("stations.id s_id,staffs.name staff_name").where(
      :"stations.store_id"=>params[:store_id],:"station_staff_relations.current_day"=>now_date).group_by{|i|i.s_id} #查询所有当天的技师信息

    #查询所有工单对应的车牌号等信息
    work_orders = Station.find_by_sql("select s.id  station_id,s.status s_status, TIMESTAMPDIFF(minute,now(),w.ended_at)
      time_left, c.num as car_num, w.status as work_order_status, w.updated_at as wo_updated_at, o.id as oid
      from stations s inner join
      work_orders w on s.id =  w.station_id inner join orders o on w.order_id = o.id inner join
      car_nums c on o.car_num_id = c.id where s.store_id = #{params[:store_id]} and w.current_day = #{now_date} and
      o.status != #{Order::STATUS[:DELETED]} order by w.started_at asc").group_by{|i|i.station_id}
    oprs = OrderProdRelation.joins(:product).select("products.name,order_id").where(:"products.is_service"=>Product::PROD_TYPES[:SERVICE]).group_by{|i|i.order_id}
    stations.each do |station| #遍历所有工位
      #为该工位加入技师信息
      station[:cons_staffs] = cons_staffs[station.id].nil? ? nil : cons_staffs[station.id].map(&:staff_name)
      #如果没有正在施工的车辆，则正在施工的车牌、剩余时间为空
      station[:dealing_car_num] = nil
      station[:dealing_time_left] = nil
      station[:s_name] = nil
      work_orders[station.id].each do |work_order|
        # STATUS = {0=>"等待服务中",1=>"服务中",2=>"等待付款",3=>"已完成"}
        # STAT = {:WAIT=>0,:SERVICING=>1,:WAIT_PAY=>2,:COMPLETE=>3}
        if work_order.work_order_status == WorkOrder::STAT[:WAIT_PAY] ||
            (work_order.work_order_status == WorkOrder::STAT[:COMPLETE] &&
              (Time.now - work_order.wo_updated_at)/60 <= 1)    #等待付款车牌号
          wait_pay_car_nums << work_order.car_num
        end
        if work_order.work_order_status == WorkOrder::STAT[:SERVICING]  #正在施工的车牌号,剩余时间及服务项目名称
          station[:dealing_car_num] = work_order.car_num
          station[:dealing_time_left] = work_order.time_left
          station[:dealing_time_left] = 0 if station[:dealing_time_left].to_i  < 0
          station[:s_name] = oprs[work_order.oid].nil? ? nil : oprs[work_order.oid].inject([]){|a, o| a << o.name;a}.join(",")
        end
      end unless work_orders[station.id].nil?
      if station.status == Station::STAT[:NORMAL]
        normal_station << station
      end
    end unless stations.blank? # if station.status == Station::STAT[:NORMAL] 结束标记

    current_info[:wait_pay_car_nums] = wait_pay_car_nums.length == 0 ? nil : wait_pay_car_nums.uniq
    current_info[:station_infos] = normal_station.blank? ? nil : normal_station
    #查出所有总部的有效的活动
    hs = Sale.find_by_sql(["SELECT s.img_url,'#{Constant::HEAD_OFFICE_API_PATH}' c_path from lantan_store.sales s where s.status=? and
           ((s.disc_time_types in (?)) or (s.disc_time_types=? and DATE_FORMAT(s.ended_at,'%Y-%m-%d')>=DATE_FORMAT(NOW(),'%Y-%m-%d')))#",
        Sale::STATUS[:RELEASE],Sale::TOTAL_DISC,Sale::DISC_TIME[:TIME]])

    hs <<  Sale.find_by_sql(["SELECT s.img_url,'#{Constant::SERVER_PATH}' c_path from sales s where s.status=? and s.store_id=? and
       ((s.disc_time_types in (?)) or (s.disc_time_types=? and DATE_FORMAT(s.ended_at,'%Y-%m-%d')>=DATE_FORMAT(NOW(),'%Y-%m-%d')))",
        Sale::STATUS[:RELEASE],params[:store_id].to_i,Sale::TOTAL_DISC,Sale::DISC_TIME[:TIME]])
    local_sales = hs.flatten.inject([]){|h, s|
      h << s.c_path + s.img_url unless s.img_url.nil? || s.img_url.strip == "";
      h
    }
    current_info[:no_station_wos] = Order.joins(:work_orders).where("work_orders.current_day =? and work_orders.store_id = ? and work_orders.status != ? and work_orders.station_id is null", now_date, params[:store_id], WorkOrder::STAT[:CANCELED]).map(&:car_num).map(&:num).uniq
    current_info[:local_sales] = local_sales.flatten
    render :json => current_info
  end

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
      stations_count = Station.where("store_id =? and status not in (?) ",staff.store_id, [Station::STAT[:WRONG], Station::STAT[:DELETED]]).count
    end
    render :json => {:store_id => staff.present? ? staff.store_id : 0, :status => status, :stations_count => stations_count || 0}
  end

end
