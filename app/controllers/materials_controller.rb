#encoding:utf-8
class MaterialsController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'will_paginate/array'
  layout "storage", :except => [:print]
  respond_to :json, :xml, :html
  before_filter :sign?

  #库存列表
  def index
    @materials_storages = Material.normal.paginate(:conditions => "store_id=#{params[:store_id]}",
      :per_page => Constant::PER_PAGE, :page => params[:page])
    @out_records = MatOutOrder.out_list params[:page],Constant::PER_PAGE, params[:store_id]
    @in_records = MatInOrder.in_list params[:page],Constant::PER_PAGE, params[:store_id]
    @type = 0
    @staffs = Staff.all(:select => "s.id,s.name",:from => "staffs s",
      :conditions => "s.store_id=#{params[:store_id]} and s.status=#{Staff::STATUS[:normal]}")
    @status = params[:status] if params[:status]
    @head_order_records = MaterialOrder.head_order_records params[:page], Constant::PER_PAGE, params[:store_id], @status
    @supplier_order_records = MaterialOrder.supplier_order_records params[:page], Constant::PER_PAGE, params[:store_id]
    
    @notices = Notice.kucun_notices params[:store_id]
    @notice_ids = @notices.collect{ |item| item.n_id}.join(",")
  end

  #库存列表分页
  def page_materials
    @materials_storages = Material.normal.paginate(:conditions => "store_id=#{params[:store_id]}",
      :per_page => Constant::PER_PAGE, :page => params[:page])
    respond_with(@materials_storages) do |format|
      #format.html
      format.js
    end
  end

  #入库列表分页
  def page_ins
    @in_records = MatInOrder.in_list params[:page],Constant::PER_PAGE, params[:store_id]
    respond_with(@in_records) do |f|
      f.html
      f.js
    end
  end

  #出库列表分页
  def page_outs
    @out_records = MatOutOrder.out_list params[:page],Constant::PER_PAGE, params[:store_id]
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

  #入库
  def create
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
              :types => params[:material][:types],:check_num => params[:num].strip})
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
      render :text => !mio_num.nil? && (mio_num+num) > moi_num ? 1 : 0
    end
  end

  #备注
  def remark
    #puts params[:remark],"ssss:#{params[:id]}"
    @material = Material.find_by_id(params[:id])
    @material.update_attribute(:remark,params[:remark]) if @material
    render :json => {:status => 1}.to_json
  end

  #核实
  def check
    #puts params[:num],"m_id:#{params[:id]}"
    @material = Material.find_by_id(params[:id])
    @material.update_attributes(:storage => params[:num].to_i, :check_num => 0) if @material
    render :json => {:status => 1}.to_json
  end

  #物料查询
  def search
    str = params[:name].strip.length > 0 ? "name like '%#{params[:name]}%' and types=#{params[:types]} " : "types=#{params[:types]}"
    if params[:type].to_i == 1 && params[:from]
      if params[:from].to_i == 0
        headoffice_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/search_material.json?name=#{params[:name]}&types=#{params[:types]}"
        #headoffice_api_url = "http://117.83.223.243:3001/api/materials/search_material.json?name=#{params[:name]}&types=#{params[:types]}"
        @search_materials = JSON.parse(open(URI.encode(headoffice_api_url.strip)).read)
      elsif params[:from].to_i > 0
        str += " and store_id=#{params[:store_id]} "
        @search_materials = Material.normal.all(:conditions => str)
      end
    else
      @search_materials = Material.normal.all(:conditions => str)
    end
    
    @type = params[:type].to_i == 0 ? 0 : 1
    respond_with(@search_materials,@type) do |format|
      format.html
      format.js
    end
  end

  #出库
  def out_order
    status = MatOutOrder.new_out_order params[:selected_items],params[:store_id],params[:staff]
    render :json => {:status => status}
  end

  #订货页面
  def order
    @type = 1
    @use_card_count = SvcReturnRecord.store_return_count params[:store_id]
  end

  #创建订货记录
  def material_order
    puts params[:store_id],params[:selected_items],params[:supplier],params[:use_count],params[:sale_id],params[:pay_type]
    status = MaterialOrder.make_order
    MaterialOrder.transaction do
      begin
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
                m = Material.find_by_code code
                if m.nil?
                  name = item.split("_")[4]
                  type_name = item.split("_")[5]
                  types = Material::TYPES_NAMES.key(type_name)
                  m = Material.create(:name => name, :code => code, :price => s_price,
                    :types => types , :status => 0, :storage => 0, :store_id => params[:store_id] )
                end
                mat_order_item = MatOrderItem.create({:material_order => material_order, :material => m, :material_num => item.split("_")[1],
                    :price => s_price})   if m

                mat_code_items["mat_order_items_#{index}"] = {:material_order_id => material_order.id, :material_id => m.id, :material_num => mat_order_item.material_num,:price => s_price,:m_code =>m.code}
              end
                
              #发送订货提醒给总店
              Notice.create(:store_id => params[:store_id], :content => URGE_GOODS_CONTENT, :target_id => material_order.id, :types => Notice::TYPES[:URGE_GOODS])

              material_order.update_attributes(:price => price)

              headoffice_post_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/save_mat_info"
              result = Net::HTTP.post_form(URI.parse(headoffice_post_api_url), {'material_order' => material_order.to_json, 'mat_items_code' => mat_code_items.to_json})
              p "----------------------------------"
              p result
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
      rescue
        status = 2
      end
      render :json => {:status => status, :mat_code => material_order.code}
    end
  end

  def material_order_pay
    @current_store = Store.find_by_id params[:store_id]
    @store_account = @current_store.account if @current_store
    @material_order = MaterialOrder.find_by_code params[:mat_code]
    @use_card_count = SvcReturnRecord.store_return_count params[:store_id]
  end

  def get_act_count
    #puts params[:code]
    sale = Sale.find_by_code params[:code]
    text = sale.nil? ? "" : sale.sub_content
    sale_id = sale.nil? ? "" : sale.id
    render :json => {:status => 1,:text => text,:sale_id => sale_id}
  end

  #添加物料（供应商订货）
  def add
    #puts params[:store_id]
    material = Material.find_by_code params[:code]
    material =  Material.create({:code => params[:code].strip,:name => params[:name].strip,
        :price => params[:price].strip.to_i, :storage => 0,
        :status => Material::STATUS[:NORMAL],:store_id => params[:store_id],
        :types => params[:types], :check_num => params[:count].strip}) if material.nil?
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
    #category = Category.find(params[:category].to_i)
    options = {
      :service => "create_direct_pay_by_user",
      :notify_url => Constant::SERVER_PATH+"/stores/#{params[:store_id]}/materials/alipay_complete",
      :subject => "订货支付",
      :payment_type => MaterialOrder::PAY_TYPES[:CHARGE],
      :total_fee => params[:f]
    }
    out_trade_no = MaterialOrder.find_by_code(params[:mo_code])
    options.merge!(:seller_email =>Oauth2Helper::SELLER_EMAIL, :partner =>Oauth2Helper::PARTNER,
      :_input_charset=>"utf-8", :out_trade_no=>out_trade_no)
    options.merge!(:sign_type => "MD5",
      :sign =>Digest::MD5.hexdigest(options.sort.map{|k,v|"#{k}=#{v}"}.join("&")+Oauth2Helper::PARTNER_KEY))
    u = "#{Oauth2Helper::PAGE_WAY}?#{options.sort.map{|k, v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')}"
    #puts u
    redirect_to u
  end

  #充值异步回调
  def alipay_complete
    out_trade_no=params[:out_trade_no]
    order = MaterialOrder.find_by_code out_trade_no
    if !order.nil?
      alipay_notify_url = "#{Oauth2Helper::NOTIFY_URL}?partner=#{Oauth2Helper::PARTNER}&notify_id=#{params[:notify_id]}"
      response_txt =Net::HTTP.get(URI.parse(alipay_notify_url))
      my_params = Hash.new
      request.parameters.each {|key,value|my_params[key.to_s]=value}
      my_params.delete("action")
      my_params.delete("controller")
      my_params.delete("sign")
      my_params.delete("sign_type")
      my_sign = Digest::MD5.hexdigest(my_params.sort.map{|k,v|"#{k}=#{v}"}.join("&")+Oauth2Helper::PARTNER_KEY)
      dir = "#{Rails.root}/public/compete"
      Dir.mkdir(dir)  unless File.directory?(dir)
      file_path = dir+"/#{Time.now.strftime("%Y%m%d")}.log"
      if File.exists? file_path
        file = File.open( file_path,"a")
      else
        file = File.new(file_path, "w")
      end
      file.puts "#{Time.now.strftime('%Y%m%d %H:%M:%S')}   #{request.parameters.to_s}\r\n"
      file.close
      if my_sign==params[:sign] and response_txt=="true"
        if params[:trade_status]=="WAIT_BUYER_PAY"
          render :text=>"success"
        elsif params[:trade_status]=="TRADE_FINISHED" or params[:trade_status]=="TRADE_SUCCESS"
          @@m.synchronize {
            begin
              MaterialOrder.transaction do
                order.update_attribute(:status, MaterialOrder::STATUS[:pay])
                if order.supplier_type==0
                  headoffice_post_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/update_status"
                  result = Net::HTTP.post_form(URI.parse(headoffice_post_api_url), {'mo_code' => order.code, 'mo_status' => MaterialOrder::STATUS[:pay]})
                  p "----------------------------------"
                  p result
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
          render :text=>"fail" + "<br>"
        end
      else
        redirect_to "/"
      end
    else
      render :text=>"fail" + "<br>"
    end
  end

  #打印
  def print
    @materials_storages = Material.normal.all(:conditions => "store_id=#{params[:store_id]}")
  end

  #订货订单的备注
  def order_remark
    if params[:order_id]
      order = MaterialOrder.find_by_id params[:order_id]
      if order
        order.update_attribute(:remark, params[:remark])
      end
    end
    render :json => {:status => 1}.to_json
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

  #取消订货订单
  def cancel_order
    if params[:order_id]
      order = MaterialOrder.find_by_id params[:order_id]
      content = "订单取消成功"
      if order && order.status == MaterialOrder::STATUS[:no_pay] && order.m_status == MaterialOrder::M_STATUS[:no_send]
        order.update_attribute(:status,MaterialOrder::STATUS[:cancel])
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
    if params[:order_id]
      order = MaterialOrder.find_by_id params[:order_id]
      content = ""
      if order && order.m_status == MaterialOrder::M_STATUS[:send]
        order.update_attribute(:m_status,MaterialOrder::M_STATUS[:received])
        content = "收货成功"
      elsif order.m_status == MaterialOrder::M_STATUS[:received]
        content = "订单已收货"
      else
        content = "收货失败"
      end
    end
    render :json => {:status => 1,:content => content}.to_json
  end

  #订单支付
  def pay_order
    if params[:mo_id]
      @mat_order = MaterialOrder.find params[:mo_id]
    end
    if @mat_order
      #支付方式
      if params[:pay_type].to_i == 1   #支付宝
        url = "/stores/#{params[:store_id]}/materials/alipay?f="+@mat_order.price.to_s
        render :json => {:status => -1,:pay_type => params[:pay_type].to_i,:pay_req => url}
      elsif params[:pay_type].to_i == 3 || params[:pay_type].to_i == 4 || params[:pay_type].to_i == 5 #现金已支付 #使用储值卡  #现金未支付
        @mat_order.update_attribute(:status, MaterialOrder::STATUS[:pay]) unless params[:pay_type].to_i == 5
        #使用储值抵货款
        if params[:use_count].to_i > 0
          SvcReturnRecord.create({
              :store_id => params[:store_id],:types => SvcReturnRecord::TYPES[:out],
              :price => params[:use_count]
            })
        end
        #使用活动代码
        if params[:sale_id]
          @mat_order.update_attribute(:sale_id,params[:sale_id])
        end
        #支付记录
        MOrderType.create(:material_order_id => @mat_order.id,:pay_types => params[:pay_type], :price => @mat_order.price)
        if params[:pay_type].to_i == MaterialOrder::PAY_TYPES[:STORE_CARD]
          @current_store = Store.find_by_id params[:store_id]
          @current_store.update_attribute(:account, @current_store.account - @mat_order.price) if @current_store
        end
        headoffice_post_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/update_status"
        result = Net::HTTP.post_form(URI.parse(headoffice_post_api_url), {'mo_code' => @mat_order.code, 'mo_status' => MaterialOrder::STATUS[:pay]})
        p "----------------------------------"
        p result
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

  def mat_order_detail
    @mo = MaterialOrder.find params[:id]
    @store_id = params[:store_id]
    @total_money = 0
    @mo.mat_order_items.each do |moi|
      @total_money += moi.price * moi.material_num
    end
  end

  def add_material
    store = Store.find params[:store_id]
    material = Material.find_by_code(params[:materials][:code])
    if material.nil?
      store.materials << Material.create(params[:materials])
    else
      storage = material.storage + params[:materials][:storage].to_i
      material.update_attributes(:storage => storage)
    end
    redirect_to "/stores/#{params[:store_id]}/materials"
  end
end