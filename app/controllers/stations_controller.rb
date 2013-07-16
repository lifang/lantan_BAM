#encoding: utf-8
class StationsController < ApplicationController
  # 现场管理 -- 施工现场
  before_filter :sign?, :except => [:simple_station]
  layout 'station'

  #施工现场
  def index
    @stations =Station.where("store_id=#{params[:store_id]} and status !=#{Station::STAT[:DELETED]}")
    sql=Station.make_data(params[:store_id])
    work_orders=WorkOrder.find_by_sql(sql).inject(Hash.new) { |hash, a| hash[a.status].nil? ? hash[a.status]=[a] : hash[a.status] << a;hash}
    waits =work_orders[WorkOrder::STAT[:WAIT_PAY]].nil? ? {} : work_orders[WorkOrder::STAT[:WAIT_PAY]]
    @f_waiting =waits.inject(Hash.new) { |hash, a| hash[a.front_staff_id].nil? ? hash[a.front_staff_id]=[a] : hash[a.front_staff_id] << a;hash}
    servs =work_orders[WorkOrder::STAT[:SERVICING]].nil? ? {} : work_orders[WorkOrder::STAT[:SERVICING]]
    @f_working =servs.inject(Hash.new) { |hash, a| hash[a.front_staff_id].nil? ? hash[a.front_staff_id]=[a] : hash[a.front_staff_id] << a;hash}
    nums=servs.inject(Hash.new) { |hash, a| hash.merge(a.station_id=>a.num)}
    @t_infos={}
    @stations.each do |station|
      staff=StationStaffRelation.find_by_sql("select staff_id from station_staff_relations where station_id=#{station.id}  and current_day='#{Time.now.strftime("%Y%m%d")}' ")
      @t_infos[station.id]=[Staff.where("id in (#{staff.map(&:staff_id).join(',')})").map(&:name).join("、 "),nums[station.id]] unless staff.blank?
#    WorkOrder.where("store_id=#{}")
    end
    p @t_infos
  end

  def show_detail
    @stations =Station.where("store_id=#{params[:store_id]} and status !=#{Station::STAT[:DELETED]}")
    @t_infos={}
    @stations.each do |station|
      staff=StationStaffRelation.find_by_sql("select staff_id from station_staff_relations where station_id=#{station.id} and current_day='#{Time.now.strftime("%Y%m%d")}' ")
      @t_infos[station.id]=Staff.where("id in (#{staff.map(&:staff_id).join(',')})").map(&:id)  unless staff.blank?
    end
    @staffs = Staff.find_by_sql("select name,id from staffs where store_id=#{params[:store_id]} and status = #{Staff::STATUS[:normal]} and type_of_w=#{Staff::S_COMPANY[:TECHNICIAN]}")
  end

  def create
    stations =Station.where("store_id=#{params[:store_id]} and status !=#{Station::STAT[:DELETED]}")
    stations.each {|station|
      if params[:"stat#{station.id}"].to_i==Station::STAT[:NORMAL]
        station.update_attributes(:status=>params[:"stat#{station.id}"].to_i)
        station.station_staff_relations.where("current_day=#{Time.now.strftime("%Y%m%d")}").inject(Array.new) {|arr,mat| mat.destroy if mat.current_day==Time.now.strftime("%Y%m%d").to_i}
        params[:"select#{station.id}"].each {|staff_id|
          StationStaffRelation.create(:station_id=>station.id,:staff_id=>staff_id,:current_day=>Time.now.strftime("%Y%m%d")) }
      else
        station.update_attributes(:status=>params[:"stat#{station.id}"].to_i)
      end
    }
    redirect_to "/stores/#{params[:store_id]}/stations/show_detail"
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
    store_id = Store.first.try(:id)
    @stations = Station.where("store_id=#{store_id} and status !=#{Station::STAT[:DELETED]}")
    @staff_stations = {}
    @stations.each do |station|
      @staff_stations[station.id] = station.staffs.where("current_day=DATE_FORMAT(NOW(),'%Y%m%d')")
    end
    render :layout => false
  end
end
