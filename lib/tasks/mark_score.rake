#encoding: utf-8
desc "AS how the staff do to mark them scores"
task(:reward_punish => :environment) do
  Store.all.each {|store_id| Station.set_stations(store_id)}
end