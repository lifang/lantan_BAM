#encoding: utf-8
desc "judge whether to reward or punish the staff or not"
task(:mark_score => :environment) do
  Store.all.each {|store_id| Station.set_stations(store_id)}
end