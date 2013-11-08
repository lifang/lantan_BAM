#encoding: utf-8
namespace :monthly do
  desc "generate chart from google_chart by diffent types of complaint"
  task(:operate_charts => :environment) do
    Store.all.each {|store| Complaint.gchart(store.id)}
  end
  
  task(:operate_satify => :environment) do
    Store.all.each {|store| Complaint.degree_chart(store.id)}
  end


  desc "generate front and technician average chart image"
  task(:generate_avg_chart_image => :environment) do
    ChartImage.generate_avg_chart_image
  end

  desc "generate staff score chart image"
  task(:generate_staff_score_chart_image => :environment) do
    ChartImage.generate_staff_score_chart
  end
end

task(:change_types => :environment) do
  Store.where(:status=>Store::STATUS[:OPENED]).each do |store|
    #需要先把预存数据加进去
    
    #---记得哦
    cates = Category.where(:store_id =>store.id ).inject(Hash.new){|hash,ca|hash[ca.types].nil? ? hash[ca.types]=[ca] : hash[ca.types] << ca;hash }
    prods = Product.where(:status=>Product::IS_VALIDATE[:YES]).inject(Hash.new){|hash,prod|
      prod_types = prod.is_service ? "service" : "prod";
      hash[prod_types].nil? ? hash[prod_types]=[prod] : hash[prod_types] << prod;hash}
    prods["prod"].each {|pro| pro.update_attributes(:category_id=>cates[Category::TYPES[:good]].shuffle[0].id)} if cates[Category::TYPES[:good]]
    prods["service"].each {|pro| pro.update_attributes(:category_id=>cates[Category::TYPES[:service]].shuffle[0].id)} if cates[Category::TYPES[:service]]
    Material.where(:status=>Material::STATUS[:NORMAL]).each {|mat| mat.update_attributes(:category_id=>cates[Category::TYPES[:material]].shuffle[0].id)} if cates[Category::TYPES[:material]]
  end
end



