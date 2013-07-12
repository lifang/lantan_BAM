#encoding: utf-8
desc "filter the right staff for stations"
namespace :daily do
  task(:set_stations => :environment) do
    Store.all.each {|store| Station.set_stations(store.id)}
  end
  task(:set_station => :environment) do
    Store.all.each {|store|
      StationStaffRelation.where("current_day=#{Time.now.strftime("%Y%m%d")} and store_id=#{store.id}").each {|station| station.destroy}
      Staff.where("store_id=#{store.id} and type_of_w=#{Staff::S_COMPANY[:TECHNICIAN]} and status=#{Staff::STATUS[:normal]}").each {|staff|
        Station.set_station(store.id,staff.id,staff.level)
      }
    }
  end
  task(:sync_local_data => :environment) do
    Store.all.each {|store| Sync.out_data(store.id)}
  end

  task(:request_zip_again => :environment) do
    #syncs = Sync.where("types=#{Sync::SYNC_TYPE[:SETIN]} and (sync_status == null or sync_status = #{Sync::SYNC_STAT[:ERROR]})")
    #syncs.each do |sync|
    #  day = (Time.now - sync.created_at).strftime("%d")
    #  Sync.request_is_generate_zip(day)
    #end
    Sync.request_is_generate_zip(Time.now)
  end

end