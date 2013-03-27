#encoding: utf-8
desc "filter the right staff for stations"
namespace :daily do
  task(:set_stations => :environment) do
    Store.all.each {|store| Station.set_stations(store.id)}
  end
  task(:sync_local_data => :environment) do
    Store.all.each {|store| Sync.out_data(store.id)}
  end
end