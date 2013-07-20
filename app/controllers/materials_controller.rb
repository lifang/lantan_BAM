#encoding:utf-8
class MaterialsController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'will_paginate/array'
  layout "storage", :except => [:print]
  respond_to :json, :xml, :html
  before_filter :sign?,:except=>["alipay_complete"]
  before_filter :material_order_tips, :only =>[:index, :receive_order, :tuihuo]
  before_filter :make_search_sql, :only => [:search_materials, :page_materials, :page_ins, :page_outs]
  before_filter :get_store, :only => [:index, :search_materials, :page_materials, :page_ins, :page_outs, :check_mat_num, :page_materials_losses]
  @@m = Mutex.new

  #库存列表
  def index
    @material_losses = MaterialLoss.list params[:page],Constant::PER_PAGE, params[:store_id].to_i
    @materials_storages = Material.includes(:mat_depot_relations).where(["status = ? and store_id = ?", Material::STATUS[:NORMAL], @current_store.id]).paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    @out_records = MatOutOrder.out_list params[:page],Constant::PER_PAGE, params[:store_id].to_i
    @in_records = MatInOrder.in_list params[:page],Constant::PER_PAGE, params[:store_id].to_i
    @type = 0
    @staffs = Staff.all(:select => "s.id,s.name",:from => "staffs s",
      :conditions => "s.store_id=#{params[:store_id].to_i} and s.status=#{Staff::STATUS[:normal]}")
    @status = params[:status] if params[:status]
    @head_order_records = MaterialOrder.head_order_records(params[:page], Constant::PER_PAGE, params[:store_id].to_i, @status)
    @supplier_order_records = MaterialOrder.supplier_order_records params[:page], Constant::PER_PAGE, params[:store_id].to_i
    @material_order_urgent = MaterialOrder.where(:id => @material_pay_notices.map(&:target_id))
    @mat_in = params[:mat_in] if params[:mat_in]
    @low_materials = Material.where(["status = ? and store_id = ? and storage<=material_low
                                    and is_ignore = ?", Material::STATUS[:NORMAL],@current_store.id, Material::IS_IGNORE[:NO]])  #查出所有该门店的低于门店物料预警数目的物料
    date_now = Time.now.to_s[0..9]
    before_thirty_day =  (Time.now - 30.day).to_s[0..9]
    @unsalable_materials = Material.find_by_sql("select * from materials where id not in (SELECT material_id as id FROM mat_out_orders  where created_at >= '#{before_thirty_day} 00:00:00' and created_at <= '#{date_now} 23:59:59'
      and  types = 3 and store_id = #{@current_store.id} group by material_id having count(material_id) >= 1) and store_id = #{@current_store.id} and status != #{Material::STATUS[:DELETE]};")
    #入库查询状态未完全入库的订货单号
    @material_orders_not_all_in = MaterialOrder.joins(:materials).where("material_orders.m_status not in (?) and material_orders.status != ? and material_orders.store_id = ?",[3,4], MaterialOrder::STATUS[:cancel], params[:store_id]).order("material_orders.created_at desc").select("material_orders.id, material_orders.code").uniq
    @mat_loss_search_materials = []
    respond_to do |format|
      format.html
      format.js
    end
  end

  def search_materials
    @tab_name = params[:tab_name]
    if @tab_name == 'materials' and params[:mat_in_flag]!="1"
      materials = Material.where(["status = ? and store_id = ?", Material::STATUS[:NORMAL], @current_store.id]).where(
        @s_sql[0]).where(@s_sql[1]).where(@s_sql[2])
      @materials_storages = materials.paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    elsif @tab_name == "material_losses_materials"
      @mat_loss_search_materials = Material.where(["status = ? and store_id = ?", Material::STATUS[:NORMAL], @current_store.id]).where(
          @s_sql[0]).where(@s_sql[1]).where(@s_sql[2])
    elsif @tab_name == 'material_losses'
      @l_sql = []
      @l_sql <<  params[:mat_code] << params[:mat_name] << params[:mat_type]
      @material_losses = MaterialLoss.list params[:page],Constant::PER_PAGE, params[:store_id],@l_sql
    elsif  @tab_name == 'in_records'
      @in_records = MatInOrder.in_list params[:page],Constant::PER_PAGE, params[:store_id].to_i,@s_sql
    elsif @tab_name == 'out_records'
      @out_records = MatOutOrder.out_list params[:page],Constant::PER_PAGE, params[:store_id].to_i,@s_sql
    end
    if params[:mat_in_flag]=="1"
       materials = Material.joins(:material_orders).where(["materials.status = ? and materials.store_id = ?", Material::STATUS[:NORMAL], @current_store.id]).where(
        @s_sql[0]).where(@s_sql[1]).where(@s_sql[2]).where(@s_sql[3]).uniq
      @material_ins = []
      materials.each do |material|
        if params[:mo_code].present?
          temp_material_orders = MaterialOrder.where({:id => params[:mo_code]})
        else
          temp_material_orders = material.material_orders.not_all_in
        end
        
        material_orders = get_mo(material, temp_material_orders)
        material_orders.each do |mo, left_num|
          mm ={:mo_code => mo.code, :mo_id => mo.id, :mat_code => material.code,:mat_num => left_num,
            :mat_name => material.name,:mat_unit => material.unit, :mat_price => material.price, :mat_id => material.id}
        @material_ins << mm
        end
      end if materials
    end
  end

  #库存列表分页
  def page_materials
    @materials_storages = Material.where(["status = ? and store_id = ?", Material::STATUS[:NORMAL],@current_store.id]).where(
      @s_sql[0]).where(@s_sql[1]).where(@s_sql[2]).paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    respond_with(@materials_storages) do |format|
      format.js
    end
  end

  #入库列表分页
  def page_ins
    @in_records = MatInOrder.in_list params[:page],Constant::PER_PAGE, params[:store_id], @s_sql
    respond_with(@in_records) do |f|
      f.html
      f.js
    end
  end

  #出库列表分页
  def page_outs
    @out_records = MatOutOrder.out_list params[:page],Constant::PER_PAGE, params[:store_id], @s_sql
    respond_with(@out_records) do |f|
      f.html
      f.js
    end
  end

  #向总部订货分页
  def page_head_orders
    @head_order_records =  []
    if params[:from] || params[:to]
      @head_order_records =  MaterialOrder.search_orders params[:store_id], params[:from],params[:to],params[:status].to_i,
        0,params[:page],Constant::PER_PAGE,params[:m_status].to_i
    else
      @head_order_records = MaterialOrder.head_order_records params[:page], Constant::PER_PAGE, params[:store_id]
    end
    respond_with(@head_order_records) do |f|
      f.html
      f.js
    end
  end

  #向供应商订货分页
  def page_supplier_orders
    @supplier_order_records = []
    if params[:from] || params[:to]
      @supplier_order_records = MaterialOrder.search_orders params[:store_id], params[:from],params[:to],params[:status].to_i,
        1,params[:page],Constant::PER_PAGE,params[:m_status].to_i
    else
      @supplier_order_records =  MaterialOrder.supplier_order_records params[:page], Constant::PER_PAGE, params[:store_id]
    end

    respond_with(@supplier_order_records) do |f|
      f.html
      f.js
    end
  end

  #库存报损分页
  def page_materials_losses
    @l_sql = []
    @l_sql <<  @mat_code << @mat_name << @mat_type
    @material_losses = MaterialLoss.list params[:page],Constant::PER_PAGE, params[:store_id], @l_sql
    respond_with(@material_losses) do |format|
      format.html
      format.js
    end
  end

  #入库
  def mat_in
    @material = Material.find_by_code_and_status_and_store_id params[:barcode].strip,Material::STATUS[:NORMAL],params[:store_id]
    @material_order = MaterialOrder.find_by_code params[:code].strip
    Material.transaction do
      begin
        if @material
          @material.update_attribute(:storage, @material.storage.to_i + params[:num].to_i)
        else
          @material = Material.create({:code => params[:barcode].strip,:name => params[:name].strip,
              :price => params[:price].strip, :storage => params[:num].strip,
              :status => Material::STATUS[:NORMAL],:store_id => params[:store_id],
              :types => params[:material][:types], :is_ignore => Material::IS_IGNORE[:NO],
              :material_low => Material::DEFAULT_MATERIAL_LOW})
        end
        if @material_order
          MatInOrder.create({:material => @material, :material_order => @material_order, :material_num => params[:num],
              :price => params[:price],:staff_id => cookies[:user_id]})
          #检查是否可以更新成已入库状态
          if @material_order.check_material_order_status
            @material_order.m_status = 3
            @material_order.save
          end
        else
          MatInOrder.create({:material => @material, :material_num => params[:num],:price => params[:price],
              :staff_id => cookies[:user_id]})
        end
      rescue

      end
    end
    redirect_to store_materials_path(params[:store_id])
  end

  #判断订货数目与入库数目是否一致
  def check_nums
    num = params[:num].to_i
    material = Material.find_by_code_and_status_and_store_id params[:barcode],Material::STATUS[:NORMAL],params[:store_id]
    material_order = MaterialOrder.find_by_code params[:mo_code]
    
    if material.nil? || material_order.nil?
      render :text => "error"
    else
      mio_num = MatInOrder.where(:material_id => material.id, :material_order_id => material_order.id).sum(:material_num)
      moi_num = MatOrderItem.find_by_material_id_and_material_order_id(material.id, material_order.id).try(:material_num)
      if moi_num.nil?
        render :text => "error" 
      else
        render :text => !mio_num.nil? && (mio_num+num) > moi_num ? 1 : 0
      end
    end
  end

  #备注
  def remark
    material = Material.find_by_id_and_store_id(params[:id], params[:store_id])
    material.update_attribute(:remark,params[:remark]) if material
    render :text => 1
  end

  #显示备注框
  def get_remark
    @store = Store.find params[:store_id]
    @material = Material.find_by_id_and_store_id(params[:id], params[:store_id])
  end

  #核实
  def check
    #puts params[:num],"m_id:#{params[:id]}"
    material = Material.find_by_id_and_store_id(params[:id], params[:store_id])
    #current_store = Store.find_by_id(params[:store_id].to_i)
    if material.update_attributes(:storage => params[:num].to_i, :check_num => nil)
      render :json => {:status => 1, :material_low => material.material_low, :material_storage => material.storage,
                          :material_code => material.code, :material_name => material.name,
                          :material_type => Material::TYPES_NAMES[material.types], :material_price => material.price}
    else
      render :json => {:status => 0}
    end
  end

  #物料查询
  def search
    str = ["status = ?", Material::STATUS[:NORMAL]]
    if params[:name].strip.length > 0
      str[0] += " and name like ?"
      str << "%#{params[:name]}%"
    end
    if params[:types].strip.length > 0
      str[0] += " and types = ?"
      str << "#{params[:types]}"
    end
     if params[:store_id].present?
      str[0] += " and store_id = ?"
      str << "#{params[:store_id]}"
    end
    if params[:type].to_i == 1 && params[:from]
      if params[:from].to_i == 0
        headoffice_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/search_material.json?name=#{params[:name]}&types=#{params[:types]}"
        result = begin
                   open(URI.encode(headoffice_api_url.strip), &:read)
                 rescue Errno::ETIMEDOUT
                   open(URI.encode(headoffice_api_url.strip), &:read)
                 end
        @search_materials = JSON.parse(result)
      elsif params[:from].to_i > 0
        @search_materials = Material.where(str)
      end
    else
      @search_materials = Material.where(str)
    end
    
    @type = params[:type].to_i
    respond_with(@search_materials,@type) do |format|
      format.html
      format.js
    end
  end

  #出库
  def out_order
    status = MatOutOrder.new_out_order params[:selected_items],params[:store_id],params[:staff], params[:types]
    render :json => {:status => status}
  end

  #创建订货记录
  def material_order
    status = MaterialOrder.make_order
    MaterialOrder.transaction do
      
        if params[:supplier]
          #向总部订货
          if params[:supplier].to_i == 0
            #生成订单
            material_order = MaterialOrder.create({
                :supplier_id => params[:supplier], :supplier_type => Supplier::TYPES[:head],
                :code => MaterialOrder.material_order_code(params[:store_id].to_i), :status => MaterialOrder::STATUS[:no_pay],
                :m_status => MaterialOrder::M_STATUS[:no_send],
                :staff_id => cookies[:user_id],:store_id => params[:store_id]
              })
            if material_order
              price = 0
              #订单相关的物料
              mat_code_items = {}
              params[:selected_items].split(",").each_with_index do |item, index|
                #                  mat_code_items[index] = {}
                price += item.split("_")[2].to_f * item.split("_")[1].to_i
                code = item.split("_")[3]
                s_price = item.split("_")[2].to_f
                m = Material.find_by_code_and_store_id code, params[:store_id]
                if m.nil?
                  name = item.split("_")[4]
                  type_name = item.split("_")[5]
                  types = Material::TYPES_NAMES.key(type_name)
                  Material.transaction do
                    m = Material.create(:name => name, :code => code, :price => s_price,
                      :types => types , :status => 0, :storage => 0, :store_id => params[:store_id],
                    :material_low => Material::DEFAULT_MATERIAL_LOW)

                  end
                end
                mat_order_item = MatOrderItem.create({:material_order => material_order, :material => m, :material_num => item.split("_")[1],
                    :price => s_price})   if m

                mat_code_items["mat_order_items_#{index}"] = {:material_order_id => material_order.id, :material_id => m.id, :material_num => mat_order_item.material_num,:price => s_price,:m_code =>m.code} if m
              end
                
              #发送订货提醒给总店
              Notice.create(:store_id => params[:store_id], :content => URGE_GOODS_CONTENT, :target_id => material_order.id, :types => Notice::TYPES[:URGE_GOODS],:status => Notice::STATUS[:NORMAL])

              material_order.update_attributes(:price => price)
              headoffice_post_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/save_mat_info"
            begin
              result = Net::HTTP.post_form(URI.parse(headoffice_post_api_url), {'material_order' => material_order.to_json, 'mat_items_code' => mat_code_items.to_json}) if mat_code_items.present?
            rescue
              status = 2
            end
            end
            #material = Material.find_by_id_and_store_id
            #向供应商订货
          elsif params[:supplier].to_i > 0
            material_order = MaterialOrder.create({
                :supplier_id => params[:supplier], :supplier_type => Supplier::TYPES[:branch],
                :code => MaterialOrder.material_order_code(params[:store_id].to_i), :status => MaterialOrder::STATUS[:no_pay],
                :m_status => MaterialOrder::M_STATUS[:no_send],
                :staff_id => cookies[:user_id],:store_id => params[:store_id]
              })
            if material_order
              price = 0
              #订单相关的物料
              params[:selected_items].split(",").each do |item|
                price += item.split("_")[2].to_f * item.split("_")[1].to_i
                m = Material.normal.find_by_id item.split("_")[0]
                MatOrderItem.create({:material_order => material_order, :material => m, :material_num => item.split("_")[1],
                    :price => item.split("_")[2].to_f})   if m

              end
              material_order.update_attribute(:price,price)
            end
          end
        end
      
      render :json => {:status => status, :mo_id => material_order.id}
    end
  end
#付款页面
  def material_order_pay
    @current_store = Store.find_by_id params[:store_id]
    @store_account = @current_store.account if @current_store
    @material_order = MaterialOrder.find_by_id params[:mo_id]
#    @use_card_count = SvcReturnRecord.store_return_count(params[:store_id]).try(:abs) # 先不提交
  end

#检验付款页面的"活动代码"
  def get_act_count
    #puts params[:code]
    sale = Sale.valid.find_by_code params[:code]
    if sale
      material_order = MaterialOrder.find(params[:mo_id])
      mats_codes = material_order.materials.map(&:code)
      sale_materials_codes = sale.products.service.map{|p| p.materials.map(&:code)}.flatten
      match_material = mats_codes&sale_materials_codes
      sale = nil if match_material.empty?
    end
    text = sale.nil? ? "" : sale.sub_content
    sale_id = sale.nil? ? "" : sale.id
    render :json => {:status => 1,:text => text,:sale_id => sale_id}
  end

  #添加物料（供应商订货）
  def add
    #puts params[:store_id]
    material = Material.find_by_code_and_store_id params[:code], params[:store_id]
    material =  Material.create({:code => params[:code].strip,:name => params[:name].strip,
        :price => params[:price].strip.to_i, :storage => 0, :material_low => Material::DEFAULT_MATERIAL_LOW,
        :status => Material::STATUS[:NORMAL],:store_id => params[:store_id],
        :types => params[:types], :check_num => nil, :is_ignore => Material::IS_IGNORE[:NO]}) if material.nil?
    x = {:status => 1, :material => material}.to_json
    #puts x
    render :json => x
  end

  #查询向总部订货的订单
  def search_head_orders
    supplier_id = params[:type] && params[:type].to_i == 1 ? 1 : 0
    @head_order_records = MaterialOrder.search_orders params[:store_id],params[:from],params[:to],params[:status].to_i,
      supplier_id,params[:page],Constant::PER_PAGE,params[:m_status].to_i
    respond_with(@head_order_records) do |f|
      f.html
      f.js
    end
  end

  #查询向供应商订货的订单
  def search_supplier_orders
    supplier_id = params[:type] && params[:type].to_i == 1 ? 1 : 0
    @supplier_order_records = MaterialOrder.search_orders params[:store_id],params[:from],params[:to],params[:status].to_i,
      supplier_id,params[:page],Constant::PER_PAGE,params[:m_status].to_i
    respond_with(@supplier_order_records) do |f|
      f.html
      f.js
    end
  end

  #发送充值请求
  def alipay
    options = {
      :service => "create_direct_pay_by_user",
      :notify_url => Constant::SERVER_PATH+"/stores/#{params[:store_id]}/materials/alipay_complete",
      :subject => "订货支付",
      :total_fee => params[:f]
    }
    out_trade_no =params[:mo_code]
    options.merge!(:seller_email =>Oauth2Helper::SELLER_EMAIL, :partner =>Oauth2Helper::PARTNER,
      :_input_charset=>"utf-8", :out_trade_no=>out_trade_no,:payment_type => 1)
    options.merge!(:sign_type => "MD5",:sign =>Digest::MD5.hexdigest(options.sort.map{|k,v|"#{k}=#{v}"}.join("&")+Oauth2Helper::PARTNER_KEY))
    redirect_to "#{Oauth2Helper::PAGE_WAY}?#{options.sort.map{|k, v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')}"
  end

  #充值异步回调
  def alipay_complete
    out_trade_no=params[:out_trade_no]
    order = MaterialOrder.find_by_code out_trade_no
    alipay_notify_url = "#{Oauth2Helper::NOTIFY_URL}?partner=#{Oauth2Helper::PARTNER}&notify_id=#{params[:notify_id]}"
    response_txt =Net::HTTP.get(URI.parse(alipay_notify_url))
    my_params = Hash.new
    request.parameters.each {|key,value|my_params[key.to_s]=value}
    my_params.delete("action")
    my_params.delete("controller")
    my_params.delete("sign")
    my_params.delete("sign_type")
    my_params.delete("store_id")
    my_sign = Digest::MD5.hexdigest(my_params.sort.map{|k,v|"#{k}=#{v}"}.join("&")+Oauth2Helper::PARTNER_KEY)
    dir = "#{Rails.root}/public/logs"
    Dir.mkdir(dir)  unless File.directory?(dir)
    file = File.open(Constant::LOG_DIR+Time.now.strftime("%Y-%m").to_s+"_alipay.log","a+")
    file.write "#{Time.now.strftime('%Y%m%d %H:%M:%S')}   #{request.parameters.to_s}\r\n"
    if my_sign==params[:sign] and response_txt=="true"
      if params[:trade_status]=="WAIT_BUYER_PAY"
        render :text=>"success"
      elsif params[:trade_status]=="TRADE_FINISHED" or params[:trade_status]=="TRADE_SUCCESS"
        if order
          @@m.synchronize {
            begin
              MaterialOrder.transaction do
                order.update_attribute(:status, MaterialOrder::STATUS[:pay])
                if order.supplier_type==0
                  mat_order_types = order.m_order_types.to_json
                  headoffice_post_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/update_status"
                  result = Net::HTTP.post_form(URI.parse(headoffice_post_api_url), {'mo_code' => order.code, 'mo_status' => MaterialOrder::STATUS[:pay], 'mo_price' => order.price, 'mat_order_types' => mat_order_types})
                end
                #支付记录
                MOrderType.create(:material_order_id => order.id,:pay_types => MaterialOrder::PAY_TYPES[:CHARGE], :price => order.price)
                render :text=>"success"
              end
            rescue
              render :text=>"success"
            end
          }
        else
          file.puts "#{Time.now.strftime('%Y%m%d %H:%M:%S')} #{out_trade_no} is not Found \r\n"
        end
      else
        render :text=>"fail" + "<br>"
      end
    else
      redirect_to "/"
    end
    file.close
  end

  #打印
  def print
    @current_store = Store.find_by_id(params[:store_id].to_i)
    @materials_storages = Material.normal.all(:conditions => "store_id=#{params[:store_id]}")
  end


  #获得mat_order 的备注
  def get_mo_remark
    @store = Store.find params[:store_id]
    @material_order = MaterialOrder.find_by_id_and_store_id(params[:mo_id], params[:store_id])
  end
  
  #订货订单的备注
  def order_remark
    order = MaterialOrder.find_by_id_and_store_id(params[:mo_id], params[:store_id]) if params[:mo_id] 
    order.update_attribute(:remark, params[:remark]) if order
    render :text => '1'
  end

  #催货
  def cuihuo
    if params[:order_id]
      order = MaterialOrder.find_by_id params[:order_id]
      if order
        Notice.create(:store_id => order.store_id, :content => URGE_GOODS_CONTENT + ",订单号为：#{order.code}",
          :target_id => order.id, :types => Notice::TYPES[:URGE_GOODS])
      end
    end
    render :json => {:status => 1}.to_json
  end
  
  #退货
  def tuihuo
    @order = MaterialOrder.find_by_id(params[:id].to_i)
    if @order
      if @order.m_status == 3 || @order.m_status == 4
        @status = 0

      else
        if @order.update_attribute("m_status", MaterialOrder::M_STATUS[:returned])
          @status = 1
        else
          @status = 0
        end
      end
    else
      @status = 0
    end
    @content = @status==0 ? "操作失败" : "操作成功"
  end
  #取消订货订单
  def cancel_order
    if params[:order_id]
      order = MaterialOrder.find_by_id params[:order_id]
      content = "订单已取消成功"
      if order && order.status == MaterialOrder::STATUS[:no_pay] && order.m_status == MaterialOrder::M_STATUS[:no_send]
        order.update_attribute(:status,MaterialOrder::STATUS[:cancel])
        if order.supplier_id==0
         headoffice_post_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/update_status"
         result = Net::HTTP.post_form(URI.parse(headoffice_post_api_url), {'mo_code' => order.code, 'mo_status' => MaterialOrder::STATUS[:cancel]})
        end
      elsif order.status == MaterialOrder::STATUS[:cancel]
        content = "订单已取消"
      else
        content = "订单已经付款或已发货无法取消"
      end
    end
    render :json => {:status => 1,:content => content}.to_json
  end

  #确认收货
  def receive_order
    if params[:id]
      @order = MaterialOrder.find_by_id params[:id]
      @content = ""

      if @order #&& @order.m_status == MaterialOrder::M_STATUS[:send]
        @order.update_attribute(:m_status,MaterialOrder::M_STATUS[:received])
        @content = "收货成功"
      elsif @order.m_status == MaterialOrder::M_STATUS[:received]
        @content = "订单已收货"
      end
    end
    #render :json => {:status => 1,:content => content, :order => order}.to_json
  end

  #订单支付
  def pay_order
    if params[:mo_id]
      @mat_order = MaterialOrder.find params[:mo_id]
    end
    if @mat_order
      svc_return_records = SvcReturnRecord.find_by_target_id @mat_order.id
      #支付方式
      @mat_order.update_attributes(:price => params[:total_price])
      #使用储值抵货款
        if params[:sav_price].to_f > 0 && svc_return_records.blank?
          use_card_count = SvcReturnRecord.store_return_count params[:store_id]
          SvcReturnRecord.create({
              :store_id => params[:store_id],:types => SvcReturnRecord::TYPES[:IN],:content => "订货单号为：#{@mat_order.code},消费：#{params[:sav_price]}.",
              :price => params[:sav_price], :total_price => use_card_count+params[:sav_price].to_f,
              :target_id => @mat_order.id
            })
          MOrderType.create(:material_order_id => @mat_order.id,:pay_types => MaterialOrder::PAY_TYPES[:SAV_CARD], :price => params[:sav_price])
        end
        #使用活动代码
        if params[:sale_price].to_f > 0 && @mat_order.sale_id.blank?
          @mat_order.update_attribute(:sale_id,params[:sale_id])
          MOrderType.create(:material_order_id => @mat_order.id,:pay_types => MaterialOrder::PAY_TYPES[:SALE_CARD], :price => params[:sale_price])
        end
      if params[:pay_type].to_i == 1   #支付宝
        url = "/stores/#{params[:store_id]}/materials/alipay?f="+@mat_order.price.to_s+"&mo_code="+@mat_order.code
        render :json => {:status => -1,:pay_type => params[:pay_type].to_i,:pay_req => url}
      elsif params[:pay_type].to_i == 3 || params[:pay_type].to_i == 4 || params[:pay_type].to_i == 5 #现金已支付 #使用储值卡  #现金未支付
        @mat_order.update_attribute(:status, MaterialOrder::STATUS[:pay]) unless params[:pay_type].to_i == 5
        
        #支付记录
        MOrderType.create(:material_order_id => @mat_order.id,:pay_types => params[:pay_type], :price => @mat_order.price) unless params[:pay_type].to_i == 5
        if params[:pay_type].to_i == MaterialOrder::PAY_TYPES[:STORE_CARD]
          @current_store = Store.find_by_id params[:store_id]
          @current_store.update_attribute(:account, @current_store.account - @mat_order.price) if @current_store
        end
        if @mat_order.supplier_id==0
          mat_order_types = @mat_order.m_order_types.to_json
          headoffice_post_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/update_status"
          p headoffice_post_api_url
          result = Net::HTTP.post_form(URI.parse(headoffice_post_api_url), {'mo_code' => @mat_order.code, 'mo_status' => params[:pay_type].to_i == 5 ? 0 :MaterialOrder::STATUS[:pay], 'mo_price' => @mat_order.price, 'sale_id' => @mat_order.sale_id, 'mat_order_types' => mat_order_types})
        end
        render :json => {:status => 0}
     
      end
    else
      render :json => {:status => 2}
    end

  end

  #修改提醒状态
  def update_notices
    if params[:ids]
      (params[:ids].split(",") || []).each do |id|
        notice = Notice.find_by_id_and_store_id id.to_i,params[:store_id].to_i
        if notice && notice.status == Notice::STATUS[:NORMAL]
          notice.update_attribute(:status,Notice::STATUS[:INVALID])
        end
      end
    end
    render :json => {:status => 0}
  end
  
  #查看订货单详情
  def mat_order_detail
    @mo = MaterialOrder.find params[:id]
    @store_id = params[:store_id]
    @total_money = 0
    @mo.mat_order_items.each do |moi|
      @total_money += moi.price * moi.material_num
    end
  end

 #判断物料条形码是否唯一
  def uniq_mat_code
    material = Material.find_by_code_and_store_id(params[:code], params[:store_id])
    render :text => material.nil? ? "0" : "1"
  end

  #上传核实文件
  def upload_checknum
    check_file = params[:check_file]
    if check_file
      new_name = random_file_name(check_file.original_filename) + check_file.original_filename.split(".").reverse[0]
      FileUtils.mkdir_p Material::MAT_CHECKNUM_PATH % @store_id
      file_path = Material::MAT_CHECKNUM_PATH % @store_id + "/#{new_name}"
      File.new(file_path, 'a+')
      File.open(file_path, 'wb') do |file|
        file.write(check_file.read)
      end

      if File.exists?(file_path)
        @check_nums = {}
        File.open(file_path, "r").each_line do |line|
          #6922233613731,10
          data = line.strip.split(',')
          @check_nums[data[0]] = data[1]
        end
        @materials = Material.where(:code => @check_nums.keys, :status => Material::STATUS[:NORMAL], :store_id => @store_id)
      end
    end
  end

  #批量核实
  def batch_check
    failed_updates = []
    flash[:notice] = "盘点清单成功！"
    params[:materials].each do |id,cn|
      material = Material.find_by_id(id)
      unless material && material.update_attributes({:storage => cn[:num], :check_num => nil})
        failed_updates << cn[:code]
      end
    end unless params[:materials].blank?
    if failed_updates.length > 0
      flash[:notice] = "#{failed_updates.join('、')} 等物料核实失败！"
    end
    redirect_to "/stores/#{params[:store_id]}/materials"
  end

  #设置库存预警数目
  def set_material_low_commit
    store = Store.find_by_id(params[:store_id].to_i)
    if store.update_attribute("material_low", params[:material_low_value])
      flash[:notice] = "设置成功!"
      redirect_to store_materials_path(store)
    else
      flash[:notice] = "设置失败!"
      redirect_to store_materials_path(store)
    end
  end

  #设置单个库存预警
  def set_material_low_count
    @store_id = params[:store_id].to_i
    @material = Material.find_by_id_and_store_id(params[:id].to_i, @store_id)
  end
  
  #设置单个库存预警提交
  def set_material_low_count_commit
    material = Material.find_by_id_and_store_id(params[:mat_id].to_i,params[:store_id].to_i)
    if material.nil?
      @status = 0
    else
      if material.update_attribute("material_low", params[:low_count].to_i)
        @status = 1
        @material = material
        @low_materials = Material.where(["status = ? and store_id = ? and storage<=material_low
                                    and is_ignore = ?", Material::STATUS[:NORMAL],params[:store_id].to_i, Material::IS_IGNORE[:NO]])
      else
        @status = 0
      end
    end
  end

  def set_ignore   #设置物料忽略预警
    #current_store = Store.find_by_id(params[:store_id].to_i)
    material = Material.find_by_id_and_store_id(params[:m_id].to_i, params[:store_id])
    if material
      if material.update_attribute("is_ignore", Material::IS_IGNORE[:YES])
        render :json => {:status => 1, :material_low => material.material_low, :material_storage => material.storage}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 0}
    end
  end

  def cancel_ignore   #取消设置物料预警
    material = Material.find_by_id_and_store_id(params[:m_id].to_i,params[:store_id].to_i)
    #current_store = Store.find_by_id(params[:store_id].to_i)
    if material
      if material.update_attribute("is_ignore", Material::IS_IGNORE[:NO])
        render :json => {:status => 1, :material_low => material.material_low, :material_storage => material.storage,
                          :material_code => material.code, :material_name => material.name,
                          :material_type => Material::TYPES_NAMES[material.types], :material_price => material.price}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 0}
    end
  end

  #添加物料
  def new
    @current_store = Store.find_by_id(params[:store_id])
    @material = Material.new
    render :edit
  end

  def create
    material = Material.find_by_code_and_store_id(params[:material][:code], params[:store_id].to_i)
    if material.nil?
      params[:material][:name] = params[:material][:name].strip
      if Material.create(params[:material].merge({:status => 0, :store_id => params[:store_id].to_i,
              :storage => 0, :material_low => Material::DEFAULT_MATERIAL_LOW}))
        @status = 1
      else
        @status = 0
      end
    else
      @status = 2
    end
  end

  #编辑物料
  def edit
    @current_store = Store.find_by_id(params[:store_id])
    @material = Material.where(:id => params[:id], :store_id => params[:store_id]).first
  end

  def update
    material = Material.find_by_id_and_store_id(params[:id], params[:store_id])
    params[:material][:name] = params[:material][:name].strip
    uniq_mat = Material.where("code = ? and store_id = ? and id != ?", params[:material][:code], params[:store_id].to_i, params[:id].to_i)
    if uniq_mat.blank?   #如果code唯一
      if material.update_attributes(params[:material])
        @status = 1
        @material = material
        #@current_store = Store.find_by_id(params[:store_id].to_i)
      else
        @status = 0
      end
    else
        @status = 2
    end
#    respond_to do |format|
#      format.js
#    end
  end

  def destroy
    material = Material.where(:id => params[:id], :store_id => params[:store_id]).first
    material.update_attribute(:status, Material::STATUS[:DELETE])
    redirect_to "/stores/#{params[:store_id]}/materials"
  end

  #盘点物料清单
  def check_mat_num
    @materials_need_check = Material.find_by_sql(["select m.* from materials m where
 m.status=? and m.store_id=? and m.check_num is not null group by m.id", Material::STATUS[:NORMAL], @current_store.id])
  end

  def print_code
    @type=2
    @store_id = params[:store_id]
  end

  def output_barcode
    prints = params[:print]
    @data = []
    prints.each do |key, value|
      material = Material.find_by_id(key)
      @data << {:num => value[:print_code_num], :code_img => material.code_img}
    end
    render :layout => false
  end

  #添加库存报损
  def mat_loss_add
    count = 0
    success = 0
    @status = false
    mat_losses = params[:mat_losses]
    unless mat_losses.nil?
      mat_losses.each do |key,value|
        count +=1
        material = Material.find(mat_losses[key][:mat_id])
        if material
          if MaterialLoss.create({:loss_num =>  mat_losses[key][:mat_num].to_i,
                               :material_id => material.id,
                               :staff_id => params[:staff],
                               :store_id => params[:hidden_store_id]
                              })
            success += 1
          end
        end
      end
    end
    if count == success
      @status = true
    end

    @material_losses = MaterialLoss.list params[:page],Constant::PER_PAGE, params[:store_id].to_i
    respond_to do |f|
      f.js
    end
  end

  #删除库存报损
  def mat_loss_delete
    @status = false
    material =  MaterialLoss.find(params[:materials_loss_id].to_i)
    if material.destroy
      @status = true
      @material_losses = MaterialLoss.list params[:page],Constant::PER_PAGE, params[:store_id].to_i
    end
    respond_to do |f|
      f.js
    end
  end

  protected
  
  def make_search_sql
    mat_code_sql = params[:mat_code].blank? ? "1 = 1" : ["materials.code = ?", params[:mat_code]]
    mat_name_sql = params[:mat_name].blank? ? "1 = 1" : ["materials.name like ?", "%#{params[:mat_name]}%"]
    mat_type_sql = params[:mat_type].blank? || params[:mat_type] == "-1" ? "1 = 1" : ["materials.types = ?", params[:mat_type].to_i]
    mo_code_sql = params[:mo_code].blank? ? "1=1" : ["material_orders.id = ?", params[:mo_code]]
    @s_sql = []
    @s_sql << mat_code_sql << mat_name_sql << mat_type_sql << mo_code_sql
    @mat_code = params[:mat_code].blank? ? nil : params[:mat_code]
    @mat_name = params[:mat_name].blank? ? nil : params[:mat_name]
    @mat_type = params[:mat_type].blank? ? nil : params[:mat_type]
  end

  def get_store
    @current_store = Store.find_by_id(params[:store_id].to_i) || not_found
  end
end