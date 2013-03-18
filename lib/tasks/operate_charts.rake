#encoding: utf-8
desc "generate chart from google_chart by diffent types of complaint"
task(:operate_charts => :environment) do
  Store.all.each {|store| Complaint.gchart(store.id)}
end
task(:operate_satify => :environment) do
  Store.all.each {|store| Complaint.degree_chart(store.id)}
end



