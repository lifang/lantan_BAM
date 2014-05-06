#encoding: utf-8
class StationsController < ApplicationController
  # 现场管理 -- 施工现场
  before_filter :sign?
  layout 'station'
  require 'fileutils'

  #施工现场
  def index
    @stations =Station.where("store_id=#{params[:store_id]} and status !=#{Station::STAT[:DELETED]}")
    unless @stations.blank?
      work_orders = WorkOrder.find_by_sql(Station.make_data(params[:store_id])).inject(Hash.new) { |hash, a|
        hash[a.status].nil? ? hash[a.status]={a.front_staff_id=>[a]} : hash[a.status][a.front_staff_id].nil? ? hash[a.status][a.front_staff_id] =[a] : hash[a.status][a.front_staff_id]<< a;hash}
      @waiting_pay = work_orders[WorkOrder::STAT[:WAIT_PAY]].nil? ? {} : work_orders[WorkOrder::STAT[:WAIT_PAY]]
      @nums = work_orders[WorkOrder::STAT[:SERVICING]].nil? ? {} : work_orders[WorkOrder::STAT[:SERVICING]].values.flatten.inject(Hash.new) {
        |hash, a| hash.merge(a.station_id=>[a.num,a.order_id])}
      @staff_ids = StationStaffRelation.where(:station_id=>@stations.map(&:id),:current_day=>Time.now.strftime("%Y%m%d").to_i).
        select("staff_id t_id,station_id s_id").inject(Hash.new) {|hash,staff|
        hash[staff.s_id].nil? ? hash[staff.s_id]=[staff.t_id] : hash[staff.s_id]<<staff.t_id;hash}
      @wait_operate = work_orders[WorkOrder::STAT[:WAIT]].nil? ? {} : work_orders[WorkOrder::STAT[:WAIT]]
      @staffs = Staff.where(:id=>(@staff_ids.values | @waiting_pay.keys | @wait_operate.keys).flatten.uniq).inject(Hash.new){|hash,staff|
        hash[staff.id]=staff.name;hash}
      @times = WorkOrder.where(:store_id=>params[:store_id],:status=>WorkOrder::STAT[:SERVICING],:current_day=>Time.now.strftime('%Y%m%d').to_i).inject(Hash.new){|hash,work_order|
        hash[work_order.station_id]=work_order.ended_at.nil? ? 0 : (work_order.ended_at- Time.now);hash }
    end
  end

  def show_detail
    @stations =Station.where("store_id=#{params[:store_id]} and status !=#{Station::STAT[:DELETED]}")
    @t_infos,@t_names = {},{}
    unless @stations.blank?
      StationStaffRelation.find_by_sql("select staff_id s_id,station_id t_id from station_staff_relations where current_day='#{Time.now.strftime("%Y%m%d")}' and
     station_id in (#{@stations.map(&:id).join(',')}) ").each {|s| @t_infos[s.t_id].nil? ? @t_infos[s.t_id]=[s.s_id] : @t_infos[s.t_id] << s.s_id}
      @staffs = Staff.find_by_sql("select name,id from staffs where store_id=#{params[:store_id]} and status = #{Staff::STATUS[:normal]} and type_of_w=#{Staff::S_COMPANY[:TECHNICIAN]}")
    end
  end

  def create
    stations =Station.where("store_id=#{params[:store_id]} and status !=#{Station::STAT[:DELETED]}")
    stations.each {|station|
      if params[:"stat#{station.id}"].to_i==Station::STAT[:NORMAL]
        station.update_attributes(:status=>params[:"stat#{station.id}"].to_i)
        station.station_staff_relations.where("current_day=#{Time.now.strftime("%Y%m%d")}").inject(Array.new) {|arr,mat| mat.destroy}
        params[:"select#{station.id}"].each {|staff_id|
          StationStaffRelation.create(:station_id=>station.id,:staff_id=>staff_id,:current_day=>Time.now.strftime("%Y%m%d"),:store_id=>params[:store_id]) }
      else
        station.update_attributes(:status=>params[:"stat#{station.id}"].to_i)
      end
    }
    flash[:notice] = "技师分配成功"
    redirect_to request.referer
  end

  def show_video
    @video_hash =@video_hash=Station.filter_dir(params[:store_id])
  end


  def search
    session[:create_at],session[:end_at]=nil,nil
    session[:create_at],session[:end_at]=params[:create_at],params[:end_at]
    redirect_to "/stores/#{params[:store_id]}/stations/search_video"
  end

  def search_video
    @video_hash=Station.filter_dir(params[:store_id])
    @video_hash =@video_hash.select { |key,value| key >= session[:create_at]  } if session[:create_at] != ""
    @video_hash =@video_hash.select { |key,value| key <= session[:end_at] } if session[:end_at] != ""
    render "show_video"
  end

  def see_video
    @path=params[:url]
  end

  def simple_station
    store = Store.find_by_id(params[:store_id]) || not_found
    @stations = Station.where("store_id=#{store.id} and status !=#{Station::STAT[:DELETED]}")
    @staff_stations = {}
    @stations.each do |station|
      @staff_stations[station.id] = station.staffs.where("current_day=DATE_FORMAT(NOW(),'%Y%m%d')")
    end
    render :layout => false
  end

  #查询水、汽和施工数量
  def collect_info
    content = "sum(water_num) water,sum(gas_num) gas,count(work_orders.id) num,station_id,is_has_controller"
    conditions = "work_orders.status=#{WorkOrder::STAT[:COMPLETE]} and date_format(work_orders.updated_at,'%Y-%m')='#{Time.now.strftime('%Y-%m')}'
    and work_orders.store_id=#{params[:store_id]}"
    month_num = WorkOrder.joins(:station).select(content).group("station_id").where(conditions).inject(Hash.new){|hash,w_order| 
      hash[w_order.station_id]=[w_order.water.nil? ? 0 :(w_order.water/(10.0**6)).round(2),w_order.gas.nil? ? 0 : (w_order.gas/(10.0**6)).round(2),
        w_order.num]; hash}
    d_conditions = "work_orders.status=#{WorkOrder::STAT[:COMPLETE]} and current_day=#{Time.now.strftime('%Y%m%d').to_i} 
    and work_orders.store_id=#{params[:store_id]}"
    day_num = WorkOrder.joins(:station).select(content).group("station_id").where(d_conditions).inject(Hash.new){|hash,w_order| 
      hash[w_order.station_id]=[w_order.water.nil? ? 0 :(w_order.water/(10.0**6)).round(2),w_order.gas.nil? ? 0 : (w_order.gas/(10.0**6)).round(2),
        w_order.num];hash}
    p month_num
    render :json=>{:month_num=>month_num,:day_num=>day_num}
  end

  #取消订单、结束施工、结束付款
  def handle_order
    order = Order.find(params[:order_id])
    if order
      customer = order.customer
      is_vip = false
      if params[:types] == "cancel" && order.status == Order::STATUS[:NORMAL]
        order.return_order_pacard_num
        order.return_order_materials
        order.rearrange_station
        order.update_attribute(:status, Order::STATUS[:DELETED])
        msg = "成功取消订单！"
      else
        work_order = order.work_orders[0]
        if params[:types] == "complete_pay" && work_order.status == WorkOrder::STAT[:WAIT_PAY]
          Order.transaction do
            begin
              point,deduct,t_deduct =0,0,0
              #如果有套餐卡，则更新状态
              c_pcard_relations = CPcardRelation.find_all_by_order_id(order.id)
              unless c_pcard_relations.blank?
                c_pcard_relations.each do |cpr|
                  cpr.update_attribute(:status, CPcardRelation::STATUS[:NORMAL])
                end
                pcard = PackageCard.where(:id=>c_pcard_relations).select("ifnull(sum(deduct_percent+deduct_price),0) deduct,
                ifnull(sum(prod_point),0) point").first
                point += pcard.point
                deduct += pcard.deduct
              end
              #如果有买储值卡，则更新状态
              csvc_relations = CSvcRelation.where(:order_id => order.id)
              csvc_relations.each{|csvc_relation| csvc_relation.update_attributes({:status => CSvcRelation::STATUS[:valid], :is_billing =>false})}
              if c_pcard_relations.present? || csvc_relations.present?
                is_vip = true
              end
             
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:CASH], :price => order.price)
              wo = WorkOrder.find_by_order_id(order.id)
              wo.update_attribute(:status, WorkOrder::STAT[:COMPLETE]) if wo and wo.status==WorkOrder::STAT[:WAIT_PAY]
              order_infos = Order.joins(:order_prod_relations=>:product).select("ifnull(sum((deduct_price+deduct_percent)*pro_num),0) d_sum,
               ifnull(sum((techin_price+techin_percent)*pro_num),0) t_sum,sum(products.prod_point*order_prod_relations.pro_num) point").
                where(:"orders.id"=>order.id).first
              if order_infos
                point += order_infos.point
                deduct += order_infos.d_sum
                t_deduct += order_infos.t_sum
              end
              #生成积分的记录
              if (customer && customer.is_vip) || is_vip
                Point.create(:customer_id=>customer.customer_id,:target_id=>order.id,:target_content=>"购买产品/服务/套餐卡获得积分",:point_num=>point,:types=>Point::TYPES[:INCOME])
                customer.update_attributes({:total_point=>point+(customer.total_point.nil? ? 0 : customer.total_point),:is_vip=>is_vip})
              end
              order.update_attributes({:status=>Order::STATUS[:BEEN_PAYMENT],:is_free=>false,:front_deduct=>deduct})
              order.tech_orders.update_attributes(:own_deduct=>t_deduct/order.tech_orders.length) unless order.tech_orders.blank?
              #生成出库记录
              order_mat_infos = Order.find_by_sql(["SELECT o.id o_id, o.front_staff_id, p.id p_id, opr.pro_num material_num, m.id m_id,
              m.price m_price FROM orders o inner join order_prod_relations opr on o.id = opr.order_id inner join products p on
              p.id = opr.product_id inner join prod_mat_relations pmr on pmr.product_id = p.id inner join materials m
              on m.id = pmr.material_id where p.is_service = #{Product::PROD_TYPES[:PRODUCT]} and o.status in (?) and o.id = ?",
                  [Order::STATUS[:BEEN_PAYMENT], Order::STATUS[:FINISHED]], order.id])
              order_mat_infos.each do |omi|
                MatOutOrder.create({:material_id => omi.m_id, :staff_id => omi.front_staff_id, :material_num => omi.material_num,
                    :price => omi.m_price, :types => MatOutOrder::TYPES_VALUE[:sale], :store_id => order.store_id})
              end
              msg = "成功结束付款！"
            rescue
              msg = "系统繁忙，请重试！"
            end
          end
        elsif params[:types] == "complete_work" && work_order.status == WorkOrder::STAT[:SERVICING]
          work_order.arrange_station
          msg = "成功结束施工！"
        else
          msg = "系统繁忙，请重试！"
        end
      end
    else
      msg = "订单不存在！"
    end
    render :json=>{:msg=>msg}
  end


end
