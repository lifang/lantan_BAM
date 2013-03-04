#encoding: utf-8
class StationsController < ApplicationController
  # 现场管理 -- 施工现场
  layout 'station'

  #施工现场
  def index
    @stations =Station.where("store_id=#{params[:store_id]}")
    sql=Station.make_data(params[:store_id])
    work_orders=WorkOrder.find_by_sql(sql).inject(Hash.new) { |hash, a| hash[a.status].nil? ? hash[a.status]=[a] : hash[a.status] << a;hash}
    waits =work_orders[WorkOrder::STAT[:WAIT_PAY]].nil? ? {} : work_orders[WorkOrder::STAT[:WAIT_PAY]]
    @f_waiting =waits.inject(Hash.new) { |hash, a| hash[a.front_staff_id].nil? ? hash[a.front_staff_id]=[a] : hash[a.front_staff_id] << a;hash}
    servs =work_orders[WorkOrder::STAT[:SERVICING]].nil? ? {} : work_orders[WorkOrder::STAT[:SERVICING]]
    @f_working =servs.inject(Hash.new) { |hash, a| hash[a.front_staff_id].nil? ? hash[a.front_staff_id]=[a] : hash[a.front_staff_id] << a;hash}
    nums=servs.inject(Hash.new) { |hash, a| hash.merge(a.station_id=>a.num)}
    @t_infos={}
    @stations.each do |station|
      staff=StationStaffRelation.find_by_sql("select staff_id from station_staff_relations where station_id=#{station.id} and current_day='#{Time.now.strftime("%Y%m%d")}' ")
      @t_infos[station.id]=[Staff.where("id in (#{staff.map(&:staff_id).join(',')})").map(&:name).join("、 "),nums[station.id]] unless staff.blank?
    end
  end

  def show_detail
    @stations =Station.where("store_id=#{params[:store_id]}")
    @t_infos={}
    @stations.each do |station|
      staff=StationStaffRelation.find_by_sql("select staff_id from station_staff_relations where station_id=#{station.id} and current_day='#{Time.now.strftime("%Y%m%d")}' ")
      @t_infos[station.id]=Staff.where("id in (#{staff.map(&:staff_id).join(',')})").map(&:id)  unless staff.blank?
    end
    @staffs =Staff.find_by_sql("select name,id from staffs where store_id=#{params[:store_id]} and type_of_w=#{Staff::S_COMPANY[:TECHNICIAN]}")
    p @staffs
  end

  def create
    stations =Station.where("store_id=#{params[:store_id]}")
    stations.each {|station|
      if params[:"stat#{station.id}"].to_i==Station::STAT[:NORMAL]
        station.update_attributes(:status=>params[:"stat#{station.id}"].to_i)
        station.station_staff_relations.inject(Array.new) {|arr,mat| mat.destroy}
        params[:"select#{station.id}"].each {|staff_id|
          StationStaffRelation.create(:station_id=>station.id,:staff_id=>staff_id,:current_day=>Time.now.strftime("%Y%m%d")) }

      else
        station.update_attributes(:status=>params[:"stat#{station.id}"].to_i)
      end
    }
    redirect_to "/stores/#{params[:store_id]}/stations/show_detail"
  end
end
