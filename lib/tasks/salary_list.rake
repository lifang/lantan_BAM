#encoding: utf-8
desc "A list about the staff's detail on pay list"
task(:salary_list => :environment) do
  Store.all.each {|store_id| Station.set_stations(store_id)}
end