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
    Material::TYPES_NAMES.values.each do |mat_name|
      Category.create(:name => mat_name, :types =>Category::TYPES[:material], :store_id => store.id)
    end
    Product::PRODUCT_TYPES.select{|k,v| k<Product::PRODUCT_END}.values.each do |prod_name|
      Category.create(:name => prod_name, :types =>Category::TYPES[:good], :store_id => store.id)
    end
    Product::PRODUCT_TYPES.select{|k,v| k>=Product::PRODUCT_END}.values.each do |serv_name|
      Category.create(:name => serv_name, :types =>Category::TYPES[:service], :store_id => store.id)
    end
    #---记得哦
    cates = Category.where(:store_id =>store.id ).inject(Hash.new){|hash,ca|
      hash[ca.types].nil? ? hash[ca.types]={ca.name=>ca.id} :  hash[ca.types][ca.name]=ca.id;hash }
    prods = Product.where(:status=>Product::IS_VALIDATE[:YES],:store_id=>store.id).inject(Hash.new){|hash,prod|
      prod_types = prod.is_service ? "service" : "prod";
      hash[prod_types].nil? ? hash[prod_types]=[prod] : hash[prod_types] << prod;hash}
    prods["prod"].each {|pro| pro.update_attributes(:category_id=>cates[Category::TYPES[:good]][Product::PRODUCT_TYPES[pro.types]])} if cates[Category::TYPES[:good]] && prods["prod"]
    prods["service"].each {|pro| pro.update_attributes(:category_id=>cates[Category::TYPES[:service]][Product::PRODUCT_TYPES[pro.types]],:single_types=>Product::SINGLE_TYPE[:SIN])} if cates[Category::TYPES[:service]] && prods["service"]
    materials = Material.where(:status=>Material::STATUS[:NORMAL],:store_id=>store.id)
    materials.each {|mat| mat.update_attributes(:category_id=>cates[Category::TYPES[:material]][Material::TYPES_NAMES[mat.types]])} if cates[Category::TYPES[:material]] && materials
  end
end

task(:new_menu => :environment) do
  Menu.delete_all(:controller=>["pay_cash","finances"])
  menu1 = Menu.create(:controller=>"pay_cash",:name=>"收银")
  menu2 = Menu.create(:controller=>"finances",:name=>"财务管理")
  Store.where(:status=>Store::STATUS[:OPENED]).each do |store|
    roles = Role.where(:store_id=>store.id).where("name like '%管理员%' or name like '%店长%' or name like '%老板%'")
    roles.each do |role|
      [menu1,menu2].each do |m|
        RoleMenuRelation.delete_all(:role_id=>role.id, :menu_id => m.id)
        RoleModelRelation.delete_all(:role_id => role.id, :num => Staff::STAFF_MENUS_AND_ROLES[m.controller.to_sym],
          :model_name => m.controller)
        RoleMenuRelation.create(:role_id => role.id, :menu_id => m.id)
        RoleModelRelation.create(:role_id => role.id, :num => Staff::STAFF_MENUS_AND_ROLES[m.controller.to_sym],
          :model_name => m.controller)
      end
    end
  end
end



