#encoding: utf-8
desc "filter the right staff for stations"
task(:set_stations => :environment) do
  Store.all.each {|store| Station.set_stations(store.id)}
end