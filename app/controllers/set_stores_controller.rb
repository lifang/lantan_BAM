#encoding: utf-8
class SetStoresController < ApplicationController
  layout "role" ,:except =>["print_paper","single_print"]
  before_filter :sign?, :except => [:update]
  require 'will_paginate/array'
  
  def index
    @store = Store.find_by_id(params[:store_id].to_i)
    @store_city = City.find_by_id(@store.city_id) if @store.city_id
    @cities = City.where(["parent_id = ?", @store_city.parent_id]) if @store_city
    @province = City.where(["parent_id = ?", City::IS_PROVINCE])
  end

  def update
    store = Store.find_by_id(params[:id].to_i)
    update_sql = {:name => params[:store_name].strip, :address => params[:store_address].strip, :phone => params[:store_phone].strip,
      :contact => params[:store_contact].strip, :position => params[:store_position_x]+","+params[:store_position_y],
      :opened_at => params[:store_opened_at], :status => params[:store_status].to_i, :city_id => params[:store_city].to_i,
      :cash_auth => params[:store_cash_auth].to_i,:auto_send=>params[:auto_send]}
    update_sql.merge!(:limited_password=>Digest::MD5.hexdigest(params[:limited_password])) if permission?(:base_datas, :edit_limited_pwd) && params[:limited_password]!=""
    if store.update_attributes(update_sql)
      if !params[:store_img].nil?
        begin
          url = Store.upload_img(params[:store_img], store.id, Constant::STORE_PICS, Constant::STORE_PICSIZE)
          store.update_attribute("img_url", url)
        rescue
          flash[:notice] = "图片上传失败!"
        end
      end
      cookies.delete(:store_name) if cookies[:store_name]
      cookies[:store_name] = {:value => store.name, :path => "/", :secure => false}
      flash[:notice] = "设置成功!"
    else
      flash[:notice] = "更新失败!"
    end
    redirect_to store_set_stores_path
  end

  def select_cities   #选择省份时加载下面的所有城市
    p_id = params[:p_id]
    @cities = City.where(["parent_id = ?", p_id])
  end


  def cash_register
    @title = "收银"
    about_cash(params[:store_id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def complete_pay
    @title = "收银"
    start_time = params[:first].nil? || params[:first] == "" ? Time.now.at_beginning_of_day.strftime("%Y-%m-%d %H:%M") : Time.now.strftime("%Y-%m-%d")+" #{params[:first]}"
    end_time = params[:last].nil? || params[:last] == "" ? Time.now.end_of_day.strftime("%Y-%m-%d %H:%M") : Time.now.strftime("%Y-%m-%d")+" #{params[:last]}"
    orders = Order.joins([:car_num,:customer]).joins("left join work_orders w on w.order_id=orders.id").select("orders.*,
      customers.mobilephone phone,customers.name c_name,customers.group_name,car_nums.num c_num,w.station_id s_id,customers.id c_id").
      where(:status=>Order::OVER_CASH,:store_id=>params[:store_id]).where("date_format(orders.updated_at,'%Y-%m-%d %H:%i')>='#{start_time}' and
      date_format(orders.updated_at,'%Y-%m-%d %H:%i')<='#{end_time}'").order("orders.updated_at desc")
    @pays = OrderPayType.where(:order_id=>orders.map(&:id)).select("sum(price) total_price,pay_type").group("pay_type").inject(Hash.new){
      |hash,pay|hash[pay.pay_type] = pay.total_price;hash}
    @orders = orders.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    p @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
    @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
    staff_ids = (@orders.map(&:cons_staff_id_1)|@orders.map(&:cons_staff_id_2)|@orders.map(&:front_staff_id)).compact.uniq
    staff_ids.delete 0
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @stations = Station.find(@orders.map(&:station_id).compact.uniq).inject(Hash.new){|hash,s|hash[s.id]=s.name;hash}
  end

  def about_cash(store_id)
    orders = Order.joins([:car_num,:customer]).joins("left join work_orders w on w.order_id=orders.id").select("orders.*,customers.mobilephone,
   customers.name c_name,customers.group_name,car_nums.num c_num,car_nums.id n_id,w.station_id s_id,customers.id c_id").where(:status=>Order::CASH,
      :store_id=>store_id).order("orders.created_at desc")
    @order_prods = OrderProdRelation.order_products(orders.map(&:id))
    @orders = orders.group_by{|i|{:c_name=>i.c_name,:c_num=>i.c_num,:tel=>i.mobilephone,:g_name=>i.group_name,:c_id=>i.c_id,:n_id=>i.n_id} }
    @order_pays = OrderPayType.search_pay_order(orders.map(&:id))
    staff_ids = (orders.map(&:cons_staff_id_1)|orders.map(&:cons_staff_id_2)|orders.map(&:front_staff_id)).compact.uniq
    staff_ids.delete 0  #莫名其妙多出来staff_id为0的数据 没找到原因  目前只能排除掉
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @stations = Station.find(orders.map(&:station_id).compact.uniq).inject(Hash.new){|hash,s|hash[s.id]=s.name;hash}
  end

  def load_order
    @customer = Customer.find params[:customer_id]
    @car_num = CarNum.find params[:car_num_id]
    @orders = Order.select("orders.*").where(:status=>Order::CASH,:store_id=>params[:store_id],:customer_id=>params[:customer_id],
      :car_num_id=>@car_num.id).order("orders.created_at desc")
    @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
    prod_ids = OrderProdRelation.joins(:product).where(:order_id=>@orders.map(&:id)).select("products.category_id").map(&:category_id)
    @cates = Category.where(:store_id=>params[:store_id],:types=>[Category::TYPES[:good], Category::TYPES[:service]]).inject(Hash.new){|hash,c|
      hash[c.id]=c.name;hash}
    sv_pcard = CPcardRelation.joins(:package_card).select("package_card_id p_id").where(:customer_id=>params[:customer_id],:order_id=>@orders.map(&:id),
      :status=>CPcardRelation::STATUS[:INVALID]).map(&:p_id)
    @sv_card = []
    unless prod_ids.blank? && sv_pcard.blank?
      sv_cards = CSvcRelation.joins(:sv_card=>:svcard_prod_relations).where(:customer_id=>@customer.id,:"sv_cards.types" => SvCard::FAVOR[:SAVE]).where("
      c_svc_relations.status=#{CSvcRelation::STATUS[:valid]} or order_id in (#{@orders.map(&:id).join(',')})").select("c_svc_relations.*,sv_cards.name,
      sv_cards.store_id,svcard_prod_relations.category_id ci,svcard_prod_relations.pcard_ids pid,c_svc_relations.status sa,order_id o_id").where("sv_cards.store_id=#{params[:store_id]}")
      sv_cards.each do |sv|
        prod_ids.each do |ca|
          if sv.ci  and sv.ci.split(",").include? "#{ca}"
            @sv_card  << sv
            break
          end
        end
        sv_pcard.each do |p_id|
          if sv.pid  and sv.pid.split(",").include? "#{p_id}"
            @sv_card  << sv
            break
          end
        end
      end
    end
    @order_pays = OrderPayType.search_pay_order(@orders.map(&:id))
  end

  def pay_order
    @may_pay = OrderPayType.deal_order(request.parameters)
    about_cash(params[:store_id])  if @may_pay[0]
  end

  def print_paper
    @store = Store.find params[:store_id]
    @customer = Customer.find params[:c_id]
    @car_num = CarNum.find params[:n_id]
    @orders = Order.where(:id=>params[:o_id].split(',').compact.uniq)
    staff_ids = (@orders.map(&:cons_staff_id_1)|@orders.map(&:cons_staff_id_2)|@orders.map(&:front_staff_id)).compact.uniq
    staff_ids.delete 0
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
    @order_pays = OrderPayType.search_pay_types(@orders.map(&:id))
    if @order_pays.keys.include? OrderPayType::PAY_TYPES[:CASH]
      @cash_pay =OrderPayType.where(:order_id=>@orders.map(&:id),:pay_type=>OrderPayType::PAY_TYPES[:CASH]).first
    end
  end

  def single_print
    @store = Store.find params[:store_id]
    @orders = Order.where(:store_id=>params[:store_id],:id=>params[:order_id])
    order = @orders.first
    @customer = Customer.find order.customer_id
    @car_num = CarNum.find order.car_num_id
    staff_ids = [order.cons_staff_id_1,order.cons_staff_id_2,order.front_staff_id].compact.uniq
    staff_ids.delete 0
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @order_prods = OrderProdRelation.order_products(order.id)
    @order_pays = OrderPayType.search_pay_types(order.id)
  end

  def edit_svcard
    CSvcRelation.find(params[:card_id]).update_attributes(:id_card=>params[:number])
    render :json=>{:card_id=>params[:card_id],:number=>params[:number]}
  end

  def plus_items
    @title = "业务开单"
    @num_heads =[ "C"=>["川A","川B","川C","川D","川E","川F","川H","川J","川K","川L","川M","川Q","川R","川S","川T","川U","川V","川W","川X",
        "川Y","川Z"],
      "E"=>["鄂A","鄂B","鄂C","鄂D","鄂E","鄂F","鄂G","鄂H","鄂J","鄂K","鄂L","鄂M","鄂N","鄂P","鄂Q","鄂R","鄂S"],
      "G"=>["赣A","赣B","赣C","赣D","赣E","赣F","赣G","赣H","赣J","赣K","赣L","赣M","桂A","桂B","桂C","桂D","桂E","桂F","桂G","桂H","桂J",
        "桂K","桂L","桂M","桂N","桂P","桂R","贵A","贵B","贵C","贵D","贵E","贵F","贵G","贵H","贵J","甘A","甘B","甘C","甘D",
        "甘E","甘F","甘G","甘H","甘J","甘K","甘L","甘M","甘N","甘P"],
      "H"=>["沪A","沪B","沪C","沪D","黑A","黑B","黑C","黑D","黑E","黑F","黑G","黑H","黑J","黑K","黑L","黑M","黑N","黑P","黑R"],
      "J"=>["京A","京B","京C","京E","京F","京H","京G","津A","津B","津C","津E",
        "冀A","冀B","冀C","冀D","冀E","冀F","冀G","冀H","冀J","冀R","冀T","晋A","晋B","晋C","晋D","晋E","晋F","晋H","晋J","晋K","晋L","晋M",
        "吉A","吉B","吉C","吉D","吉E","吉F","吉G","吉H","吉J"],
      "L"=>["辽A","辽B","辽C","辽D","辽E","辽F","辽G","辽H","辽J","辽K","辽L","辽M","辽N","辽P","辽V","鲁A","鲁B","鲁C","鲁D","鲁E","鲁F",
        "鲁G","鲁H","鲁J","鲁K","鲁L","鲁M","鲁N","鲁P","鲁Q","鲁R","鲁S","鲁U","鲁V"],
      "M" =>["蒙A","蒙B","蒙C","蒙D","蒙E","蒙F","蒙G","蒙H","蒙J","蒙K","蒙L","蒙M","闽A","闽B","闽C","闽D","闽E","闽F","闽G","闽H","闽J","闽K"],
      "N" =>["宁A","宁B","宁C","宁D"],
      "Q" =>["青A","青B","青C","青D","青E","青F","青G","青H","琼A","琼B","琼C","琼D","琼E"],
      "S" =>["苏A","苏B","苏C","苏D","苏E","苏F","苏G","苏H","苏J","苏K","苏L","苏M","苏N","陕A","陕B","陕C","陕D","陕E","陕F","陕G","陕H","陕J",
        "陕K","陕U","陕V"],
      "W" =>["皖A","皖B","皖C","皖D","皖E","皖F","皖G","皖H","皖J","皖K","皖L","皖M","皖N","皖P","皖Q","皖R","皖S"],
      "X" =>["湘A","湘B","湘C","湘D","湘E","湘F","湘G","湘H","湘J","湘K","湘L","湘M","湘N","湘U","新A","新B","新C","新D","新E","新F",
        "新G","新H","新J","新K","新L","新M","新N","新P","新Q","新R"],
      "Y" =>["渝A","渝B","渝C","渝F","渝G","渝H","豫A","豫B","豫C","豫D","豫E","豫F","豫G","豫H","豫J","豫K","豫L","豫M","豫N","豫P",
        "豫Q","豫R","豫S","豫U","粤A","粤B","粤C","粤D","粤E","粤F","粤G","粤H","粤J","粤K","粤L","粤M","粤N","粤P","粤Q","粤R","粤S",
        "粤T","粤U","粤V","粤W","粤X","粤Y","粤Z","云A","云C","云D","云E","云F","云G","云H","云J","云K","云L","云M","云N","云P","云Q","云R","云S"],
      "Z" =>["浙A","浙B","浙C","浙D","浙E","浙F","浙G","浙H","浙J","浙K","浙L","藏A","藏B","藏C","藏D","藏E","藏F","藏G","藏H","藏J"],
    ]
  end


  def search_item
    type,content,store_id = params[:item_id].to_i,params[:item_name],params[:store_id].to_i
    sql,@suitable = [""],{}
    if type == Category::ITEM_NAMES[:CARD] #如果是卡类
      @cates = SvCard::S_FAVOR.merge(2=>"套餐卡")
      stores_id = chain_store(params[:store_id])  #获取该门店所有的连锁店
      sv_sql = "select * from sv_cards where  status=#{SvCard::STATUS[:NORMAL]}"
      if stores_id.blank?   #若该门店无其他连锁店
        sv_sql += " and store_id=#{store_id}"
      else    #若该门店有其他连锁店
        sv_sql += " and ((store_id=#{store_id} and use_range=#{SvCard::USE_RANGE[:LOCAL]}) or (store_id in (#{stores_id.join(',')}) and use_range =#{SvCard::USE_RANGE[:CHAINS]}))"
      end
      sv_sql += " and name like '%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%'" unless content.nil? || content.empty? || content == ""
      sv_cards = SvCard.find_by_sql(sv_sql).group_by{|i|i.types}   #获取该门店的优惠卡及其同连锁店下面的门店的使用范围为连锁店的优惠卡
      sv_cards.each do |k,cards|
        suit_cards = []
        if k == SvCard::FAVOR[:SAVE]
          cates = Category.where(:types=>Category::DATA_TYPES,:store_id=>store_id).inject({}){|h,c|h[c.id]=c.name;h}.merge!(Product::PACK_SERVIE)
          pcards = PackageCard.where(:status=>PackageCard::STAT[:NORMAL],:store_id=>store_id).inject({}){|h,c|h[c.id]=c.name;h}
          svp = SvcardProdRelation.where(:sv_card_id=>cards.map(&:id)).inject({}){|h,c|
            h[c.sv_card_id]=[c.category_id.nil? ? nil : c.category_id.split(','),c.pcard_ids.nil? ? nil : c.pcard_ids.split(',')]}
          cards.each do |card|
            field = svp[card.id] && svp[card.id][0] ? svp[card.id][0].map { |i| cates[i.to_i]}.uniq.compact.join(",") : ""
            field += svp[card.id] && svp[card.id][1] ? svp[card.id][1].map { |i| pcards[i.to_i]}.uniq.compact.join(",") : ""
            suit_cards << {:name=>card.name,:price=>card.price,:id=>card.id,:suit_field =>field,:type=>k,:status=>params[:checked_item].include?("#{type}_#{k}_#{card.id}")}
          end
        elsif k == SvCard::FAVOR[:DISCOUNT]
          p_fields = Product.find_by_sql("select group_concat(name,'-',round(sp.product_discount/10,1),'折')  name,sp.sv_card_id s_id from
         products p inner join svcard_prod_relations sp on sp.product_id=p.id where p.status=#{Product::IS_VALIDATE[:YES]} and
         sp.sv_card_id in (#{cards.map(&:id).join(',')}) group by sp.sv_card_id").inject({}){|h,s|h[s.s_id]=s.name;h}
          cards.each do |card|
            suit_cards << {:name=>card.name,:price=>card.price,:id=>card.id,:suit_field =>p_fields[card.id],:type=>k,:status=>params[:checked_item].include?("#{type}_#{k}_#{card.id}")}
          end
        end
        @suitable[k] = suit_cards unless suit_cards.blank?
      end unless sv_cards == {}
     
      #获取该门店所有的套餐卡及其所关联的物料
      suit_pcard = []
      sql2 = ["select p.* from package_cards p where p.store_id=? and ((p.date_types=?) or (p.date_types=? and NOW()<=p.ended_at))
     and p.status=?",store_id, PackageCard::TIME_SELCTED[:END_TIME],PackageCard::TIME_SELCTED[:PERIOD], PackageCard::STAT[:NORMAL]]
      unless content.nil? || content.empty? || content == ""
        sql2[0] += " and p.name like ?"
        sql2 << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      p_cards = PackageCard.find_by_sql(sql2)
      unless p_cards.blank?
        card_fields = Product.find_by_sql("select group_concat(name,':',pr.product_num,'次')  name,pr.package_card_id s_id from
         products p inner join pcard_prod_relations pr on pr.product_id=p.id where p.status=#{Product::IS_VALIDATE[:YES]} and
         pr.package_card_id in (#{p_cards.map(&:id).join(',')}) group by pr.package_card_id").inject({}){|h,s|h[s.s_id]=s.name;h}
        p_cards.each do |p_card|
          suit_pcard << {:name=>p_card.name,:price=>p_card.price,:id=>p_card.id,:suit_field =>card_fields[p_card.id],:type=>2,:status=>params[:checked_item].include?("#{type}_#{2}_#{p_card.id}")}
        end
      end
      @suitable[2] = suit_pcard unless suit_pcard.blank?
    else   #如果是产品或者服务
      @cates = Category.where(:types=>type,:store_id=>store_id).inject({}){|h,c|h[c.id]=c.name;h}.merge!(Product::PACK_SERVIE)
      sql = "select p.* from  products p inner join  categories c on c.id=p.category_id where p.store_id=#{store_id} and p.status=#{Product::IS_VALIDATE[:YES]} "
      if type== Category::ITEM_NAMES[:PROD] #如果是产品
        sql += " and c.types=#{Category::TYPES[:good]}"
      elsif type == Category::ITEM_NAMES[:SERVICE]
        sql += " and (c.types=#{Category::TYPES[:service]} or p.category_id=#{Product::PACK[:PACK]}) "
      end
      unless content.nil? || content.empty? || content == ""
        sql += " and p.name like '%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%'"
      end
      result = Product.find_by_sql(sql).group_by{|i|i.category_id}
      total_prms = ProdMatRelation.joins(:material).where(:product_id=>result.values.flatten.map(&:id)).select("FLOOR(materials.storage/material_num) num,product_id,material_id").group_by{|i|i.product_id}
      result.each do |k,prod_servs|
        suit_storage = []
        prod_servs.each do |r|
          if total_prms[r.id]
            available = true
            available_num = []
            total_prms[r.id].each do |prm|
              if prm.num <= 0
                available = false
                break
              end
              available_num << prm.num
            end
            if available
              suit_storage << {:storage=>available_num.min,:name=>r.name,:price=>r.sale_price,:id=>r.id,:type=>type,:status=>params[:checked_item].include?("#{k}_#{type}_#{r.id}")}
            end
          end
        end
        @suitable[k] = suit_storage unless suit_storage.blank?
      end
    end
    p @suitable
  end

  def search_info
    store_id = chain_store(params[:store_id])
    store_id = [params[:store_id]] unless store_id.blank?
   @customer = Customer.joins(:customer_store_relations,:customer_num_relations=>:car_num).where(:"car_nums.num"=>params[:car_num],
     :"customer_store_relations.store_id"=>store_id).select("customers.id c_id,name,mobilephone,other_way,address,group_name").where(:status=>Customer::STATUS[:NOMAL]).first
   if @customer
     CPcardRelation.find_by_sql("select p.name,c.id c_id from c_pcard_relations c on c.package_card_id=p.id where
     customer_id=#{@customer.id} and c.status=#{CPcardRelation::STATUS[:NORMAL]} and p.status = #{PackageCard::STAT[:NORMAL]}
     and p.store_id = #{params[:store_id]}")

   end
  end
  
end