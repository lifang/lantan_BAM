#encoding: utf-8
desc "filter the right staff for stations"
namespace :daily do
  task(:set_stations => :environment) do
    Store.all.each {|store| Station.set_stations(store.id)}
  end
  task(:right_data => :environment) do
    Store.all.each {|store|
      syncs =Sync.where("store_id=#{store.id} and types=#{Sync::SYNC_TYPE[:BUILD]} and has_data=#{Sync::HAS_DATA[:YES]}
             and (data_status=#{Sync::SYNC_STAT[:ERROR]} or sync_status=#{Sync::SYNC_STAT[:ERROR]})")
      syncs.each {|sync| Sync.out_data(store.id,sync.sync_at)}
    }
  end
  task(:sync_local_data => :environment) do
    Store.all.each {|store| Sync.out_data(store.id)}
  end

  task(:request_zip_again => :enviroment) do
    syncs = Sync.where("types=#{Sync::SYNC_TYPE[:SETIN]} and (sync_status == null or sync_status = #{Sync::SYNC_STAT[:ERROR]})")
    syncs.each do |sync|
      day = (Time.now - sync.created_at).strftime("%d")
      Sync.request_is_generate_zip(day)
    end
  end

end