#encoding: utf-8
class ProductsController < ApplicationController
  # 营销管理 -- 产品


  def index
    @products = Product.paginate_by_sql("select service_code code,name,types,sale_price from products where  store_id=#{2} and 
    is_service=#{Product::PROD_TYPES[:product]} and status=#{Product::IS_VALIDATE[:YES]}", :page => params[:page], :per_page => 5)
    #store_id 为硬写
  end  #产品列表页

  def create
    set_product("product")

  end  #添加产品


  def services
    @services = Product.paginate_by_sql("select id, service_code code,name,types,sale_price,cost_time,staff_level level1,staff_level_1
    level2 from products where store_id=#{2} and is_service=#{Product::PROD_TYPES[:service]} and status=#{Product::IS_VALIDATE[:YES]}",
     :page => params[:page], :per_page => 5)
    #store_id 为硬写
    @materials={}
    @services.each do |service|
      @materials[service.id]=Material.find_by_sql("select name,code from materials where id in (#{service.prod_mat_relations.map(&:material_id).join(",")})
                and store_id=2")  #store_id 为硬写
    end
    p @materials
  end   #服务列表

  def serv_create
    set_product("service")
  end   #添加服务

  def set_product(types)
    parms = {:name=>params[:name],:base_price=>params[:base_price],:sale_price=>params[:sale_price],:description=>params[:desc],
      :types=>params[:types],:code_service=>params[:code],:status=>Product::IS_VALIDATE[:YES],:introduction=>params[:intro],
      :is_service=>Product::PROD_TYPES["#{types}"],:created_at=>Time.now.strftime("%Y-%M-%d"),:img_url=>params[:img_url],
      :store_id=>2
    } #store_id 为硬写
    if types=="service"
      parms.merge!({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2]})
    else
      parms.merge!({:standard=>params[:standard]})
    end
    product=Product.create(parms)
    params[:material].each do |key,value|
      ProdMatRelation.create(:product_id=>product.id,:material_num=>value,:material_id=>key)
    end
  end   #为新建产品或者服务提供参数
end
