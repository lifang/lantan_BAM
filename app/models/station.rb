#encoding: utf-8
class Station < ActiveRecord::Base
  has_many :word_orders
  has_many :station_staff_relations
  has_many :staffs, :through => :station_staff_relations
  has_many :station_service_relations
  has_many :wk_or_times
  has_many :products, :through => :station_service_relations do
    def valid
      where("status=true and is_service=true")
    end
  end
  belongs_to :store
  STAT = {:WRONG =>0,:NORMAL =>2,:LACK =>1,:NO_SERVICE =>3, :DELETED => 4} #0 故障 1 缺少技师 2 正常 3 无服务
  STAT_NAME = {0=>"故障",1=>"缺少技师",3=>"缺少服务项目",2=>"正常", 4 => "删除"}
  PerPage = 10
  validates :name, :presence => true
  scope :valid, where("status != 4")
  
  def self.set_stations(store_id)
    p store_id
    s_levels ={}  #所需技师等级
    l_staffs ={}  #现有等级的技师
    next_turn=[]
    stations=Station.where("store_id=#{store_id} and status != #{Station::STAT[:WRONG]} and status !=#{Station::STAT[:DELETED]}")
    stations.each do |station|
      prod=Product.find_by_sql("select staff_level level1,staff_level_1 level2 from products p inner join station_service_relations  s on
      s.product_id=p.id where s.station_id=#{station.id}").inject(Array.new) {|sum,level| sum.push(level.level1,level.level2)}.compact.uniq.sort
      unless prod.blank?
        s_levels[station.id]=[prod[0..(prod.length/2.0-0.5)].max,prod.max]
      else
        Station.find(station.id).update_attributes(:status=>Station::STAT[:NO_SERVICE])
      end
    end
    Staff.find_by_sql("select name,id,level from staffs where store_id=#{store_id} and type_of_w=#{Staff::S_COMPANY[:TECHNICIAN]} and status=#{Staff::STATUS[:normal]}").each {|staff|
      if l_staffs[staff.level]
        l_staffs[staff.level].push([staff.id,staff.name])
      else
        l_staffs[staff.level]=[[staff.id,staff.name]]
      end
    }
    s_levels.each do |station,level|
      level.each_with_index do |k,index|
        if l_staffs[k].nil? || l_staffs[k].shuffle[0].nil?
          s_levels[station][index] = nil
          next_turn << [k,station,index]
        else
          s_levels[station][index] = l_staffs[k].delete(l_staffs[k].shuffle[0])
        end
      end
    end
    stills=l_staffs.delete_if {|key, value| value==[] }
    next_turn.sort_by { |turn| turn[0]  }.reverse.each {|turn|
      level_values = []  #符合条件的staff
      unless stills.select {|k,v| k >  turn[0] }.empty?
        stills.select {|k,v| k > turn[0] }.each_pair {|key,value| value.each {|val| level_values.push(val.push(key))} }
        #筛选合格的staff并记录等级
        selected_staff = level_values.shuffle[0]   #随机选取staff
        index = selected_staff.delete_at(-1)
        stills[index].delete(selected_staff)      #已选择的staff删除
        s_levels[turn[1]][turn[2]] = selected_staff   #安排staff进工位
        stills=stills.delete_if {|key, value| value == [] }
        stills.select {|k,v| k > turn[0] }.each {|key,value| value.each {|val| val.delete_at(-1)}}
        # 相应等级无staff的删除  并将符合筛选条件但没选中的staff 删除等级
      end
    }
    StationStaffRelation.find_all_by_current_day(Time.now.strftime("%Y%m%d")).each {|station| station.destroy}
    p s_levels
    s_levels.each  {|station_id,staffs|
      if staffs.include?(nil)
        Station.find(station_id).update_attributes(:status=>Station::STAT[:LACK])
      else
        Station.find(station_id).update_attributes(:status=>Station::STAT[:NORMAL])
      end
      staffs.each {|staff|
        if staff
          StationStaffRelation.create(:station_id=>station_id,:staff_id=>staff[0],:current_day=>Time.now.strftime("%Y%m%d"))
        end
      }
    }
  end

  def self.make_data(store_id)
    return  "select c.num,w.station_id,o.front_staff_id,s.name,w.status,w.order_id from work_orders w inner join orders o on w.order_id=o.id inner join car_nums c on c.id=o.car_num_id
    inner join staffs s on s.id=o.front_staff_id where current_day='#{Time.now.strftime("%Y%m%d")}' and
    w.status in (#{WorkOrder::STAT[:SERVICING]},#{WorkOrder::STAT[:WAIT_PAY]}) and w.store_id=#{store_id}"
  end

  def self.ruby_to_js(hashs)
    user_plan={}
    hashs.each do |k,v|
      user_plan["#{k}"]="#{v}"
    end
    return "#{user_plan}".gsub("=>",":")
  end

  def self.get_dir_list(path)
    #获取目录列表
    list = Dir.entries(path)
    list.delete('.')
    list.delete('..')
    return list
  end

  def self.filter_dir(store_id)
    path_dir = Constant::LOCAL_DIR
    dirs=["#{Constant::VIDEO_DIR}/","#{store_id}/"]
    dirs.each_with_index {|dir,index| Dir.mkdir path_dir+dirs[0..index].join   unless File.directory? path_dir+dirs[0..index].join }
    video_path ="/public/"+dirs.join
    paths=get_dir_list("#{Rails.root}"+video_path)
    video_hash ={}
    paths.each do |path|
      mtime =File.stat("#{Rails.root}"+video_path+path).mtime.strftime("%Y-%m-%d")
      if video_hash[mtime]
        video_hash[mtime] << "/#{dirs.join+path}"
      else
        video_hash[mtime] = ["/#{dirs.join+path}"]
      end
    end unless paths.blank?
    return video_hash
  end

  def self.arrange_time store_id, prod_ids, order = nil, res_time = nil
    #查询所有满足条件的工位
    stations = Station.includes(:wk_or_times).where(:store_id => store_id, :status => Station::STAT[:NORMAL])
    station_arr = []
    prod_ids = prod_ids.collect{|p| p.to_i }
    (stations || []).each do |station|
      if station.station_service_relations
        prods = station.station_service_relations.collect{|r| r.product_id }
        station_arr << station if (prods & prod_ids).sort == prod_ids.sort
      end
    end
    times_arr = []
    time_now = Time.now.strftime("%Y%m%d%H%M")
    times_arr << time_now
    station_id = 0
    
    #如果用户连续多次下单并且购买的服务可以在原工位上施工，则排在原来工位上。
    if order
      work_order = WorkOrder.joins(:order => :car_num).where(:car_nums => {:id => order.car_num_id},
        :work_orders => {:status => [WorkOrder::STAT[:WAIT], WorkOrder::STAT[:SERVICING]], :current_day => Time.now.strftime("%Y%m%d").to_i}).order("ended_at desc").first
      if work_order #5
        ended_at = work_order.ended_at
        last_order_ended_at = ended_at.strftime("%Y%m%d%H%M")
        times_arr << last_order_ended_at
        if station_arr.map(&:id).include?(work_order.station_id) #[1,3] 5
          station_id = work_order.station_id
        end
      end
    end
    if station_id == 0
      #按照工位的忙闲获取预计时间
      wkor_times = WkOrTime.where(:station_id => station_arr, :current_day => Time.now.strftime("%Y%m%d"))
      if wkor_times.blank?
        station_id = station_arr[0].try(:id) || 0
      else
        stations = Station.where(:id => wkor_times.map(&:station_id))
        no_order_stations = station_arr - stations #获得工位上没订单的工位
        if no_order_stations.present?
          station_id = no_order_stations[0].id
        else
          min_wkor_times = wkor_times.min{|a,b| a.current_times <=> b.current_times}
          min_ended_at = min_wkor_times.current_times
          times_arr << min_ended_at
          station_id = min_wkor_times.station_id
        end
      end
    end
    temp_time = times_arr.each{|t| Time.zone.parse(t)}.max
    time = (res_time && (temp_time < Time.zone.parse(res_time))) ? Time.zone.parse(res_time) : Time.zone.parse(temp_time)
    time_arr = [(time + Constant::W_MIN.minutes).strftime("%Y-%m-%d %H:%M"),
      (time + (Constant::W_MIN + Constant::STATION_MIN).minutes).strftime("%Y-%m-%d %H:%M"),station_id]
    #puts time_arr,"-----------------"
    time_arr
  end
end
