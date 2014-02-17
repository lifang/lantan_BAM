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


#2.3新版初始化执行程序
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

#更新收银和财务管理
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

#更新套餐卡内价格
task(:pcard_percent => :environment) do
  pcards = PackageCard.where(:status=>PackageCard::STAT[:NORMAL])
  pcardProd = PcardProdRelation.where(:package_card_id=>pcards.map(&:id)).group_by{|i|i.package_card_id}
  prods = Product.find(pcardProd.values.flatten.map(&:product_id)).inject({}){|h,p|h[p.id]=p.sale_price.nil? ? 0 : p.sale_price;h}
  pcards.each do |pcard|
    if pcardProd[pcard.id]
      total_price = pcardProd[pcard.id].inject(0){|sum,v|sum + (prods[v.product_id]*v.product_num)}
      if total_price > pcard.price.to_f
        pcard.update_attributes(:sale_percent=>pcard.price.to_f/total_price)
      end
    end
  end
end

#更新储值卡密码
task(:sv_pwd => :environment) do
  time = Time.now.to_i
  count = CSvcRelation.where(:status=>CSvcRelation::STATUS[:valid]).where("password is null").select("count(*) count").count
  CSvcRelation.where(:status=>CSvcRelation::STATUS[:valid]).where("password is null").update_all :password=>Digest::MD5.hexdigest("123456")
  p "update who has bought sv_cards,the bought_records count is #{count},the run time is #{(Time.now.to_i - time)/3600.0}"
end


#------------未更新
#添加供应商助记码
task(:set_cap_name => :environment) do
  require "toPinyin"
  time = Time.now.to_i
  count = Supplier.count("name is not null")
  Supplier.where("name is not null").map{|supplier|
    supplier_name = Supplier.where("name is not null").map(&:cap_name)
    cap_name = supplier.name.split(" ").join("").split("").map{|n|n.pinyin[0][0]}.compact.join("")
    supplier.update_attributes(:cap_name=>(supplier_name.include? cap_name) ? "#{cap_name}1" : cap_name)}
  "set the cap_name to suppliers,the  num is #{count},the run time is #{(Time.now.to_i - time)/3600.0}"
end

#添加供应商助记码
task(:set_create_prod => :environment) do
  time = Time.now.to_i
  Material.where(:status=>Material::STATUS[:NORMAL]).update_all(:create_prod=>Material::STATUS[:NORMAL])
  count = Product.where(:status=>Product::IS_VALIDATE[:YES],:is_service=>Product::PROD_TYPES[:PRODUCT]).count
  prods = Product.where(:status=>Product::IS_VALIDATE[:YES],:is_service=>Product::PROD_TYPES[:PRODUCT])
  Material.where(:id=>ProdMatRelation.where(:product_id=>prods.map(&:id)).map(&:material_id)).update_all(:create_prod=>Material::STATUS[:DELETE])
  p "set the create prod  to materials,the  num is #{count},the run time is #{(Time.now.to_i - time)/3600.0}"
end





