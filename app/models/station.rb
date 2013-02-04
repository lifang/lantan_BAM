#encoding: utf-8
class Station < ActiveRecord::Base
  has_many :word_orders
  has_many :station_staff_relations
  has_many :station_service_relations
  has_many :w_o_times
  belongs_to :store
  STAT = {:WRONG =>0,:NORMAL =>2,:LACK =>1,:NO_SERVICE =>3} #0 故障 1 缺少技师 2 正常 3 无服务

  def self.set_stations(store_id)
    s_levels ={}  #所需技师等级
    l_staffs ={}  #现有等级的技师
    next_turn=[]
    stations=Station.where("store_id=#{store_id} and status != #{Station::STAT[:WRONG]}")
    stations.each do |station|
      prod=Product.find_by_sql("select staff_level level1,staff_level_1 level2 from products p inner join station_service_relations  s on
      s.product_id=p.id where s.station_id=#{station.id}").inject(Array.new) {|sum,level| sum.push(level.level1,level.level2)}.compact.uniq.sort
      unless prod.blank?
        s_levels[station.id]=[prod[0..(prod.length/2.0-0.5)].max,prod.max]
      else
        Station.find(station.id).update_attributes(:status=>Station::STAT[:NO_SERVICE])
      end
    end
    Staff.find_by_sql("select name,id,level from staffs where store_id=#{store_id} and type_of_w=#{Staff::S_COMPANY[:TECHNICIAN]}").each {|staff|
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
end
