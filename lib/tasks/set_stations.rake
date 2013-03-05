#encoding: utf-8
desc "filter the right staff for stations"
task(:set_stations => :environment) do
  Store.all.each {|store_id| Station.set_stations(store_id)}
end