#encoding: utf-8
class ProductsController < ApplicationController
  # 营销管理 -- 产品
  layout 'sale'

  def index
    @products = Product.paginate_by_sql("select service_code code,name,types,sale_price,id from products where  store_id=#{params[:store_id]}
    and is_service=#{Product::PROD_TYPES[:PRODUCT]} and status=#{Product::IS_VALIDATE[:YES]} order by created_at desc", :page => params[:page], :per_page => 5)
  end  #产品列表页

  #新建
  def add_prod
    @product=Product.new
  end

  def create
    set_product("PRODUCT")
    redirect_to "/stores/#{params[:store_id]}/products"
  end  #添加产品


  def prod_services
    @services = Product.paginate_by_sql("select id, service_code code,name,types,base_price,cost_time,staff_level level1,staff_level_1
    level2 from products where store_id=#{params[:store_id]} and is_service=#{Product::PROD_TYPES[:SERVICE]} and status=#{Product::IS_VALIDATE[:YES]}
    order by created_at asc", :page => params[:page], :per_page => 5)
    @materials={}
    @services.each do |service|
      @materials[service.id]=Material.find_by_sql("select name,code,p.material_num num from materials m inner join prod_mat_relations p on
        p.material_id=m.id  where p.product_id=#{service.id} and store_id=#{params[:store_id]}")
    end
    p @materials
  end   #服务列表

  def serv_create
    set_product("SERVICE")
    redirect_to "/stores/#{params[:store_id]}/products/prod_services"
  end   #添加服务

  def set_product(types)
    parms = {:name=>params[:name],:base_price=>params[:base_price],:sale_price=>params[:sale_price],:description=>params[:desc],
      :types=>params[:sale_types],:status=>Product::IS_VALIDATE[:YES],:introduction=>params[:intro], :store_id=>params[:store_id],
      :is_service=>Product::PROD_TYPES[:"#{types}"],:created_at=>Time.now.strftime("%Y-%M-%d"),:img_url=>params[:img_url],
      :service_code=>"#{types[0]}#{Sale.set_code(3)}"
    }
    product=Product.create(parms)
    if types == "SERVICE"
      product.update_attributes({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2] })
      params[:material].each do |key,value|
        ProdMatRelation.create(:product_id=>product.id,:material_num=>value,:material_id=>key)
      end
    else
      product.update_attributes({:standard=>params[:standard]})
    end
  end   #为新建产品或者服务提供参数

  def edit_prod
    @product=Product.find(params[:id])
  end

  def show_prod
    @product=Product.find(params[:id])
  end

  def update_product(types,product)
    parms = {:name=>params[:name],:base_price=>params[:base_price],:sale_price=>params[:sale_price],:description=>params[:desc],
      :types=>params[:sale_types],:introduction=>params[:intro],:img_url=>params[:img_url]
    }
    if types == "SERVICE"
      parms.merge!({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2] })
      product.prod_mat_relations.inject(Array.new) {|arr,mat| mat.destroy}
      params[:material].each do |key,value|
        ProdMatRelation.create(:product_id=>product.id,:material_num=>value,:material_id=>key)
      end
    else
      parms.merge!({:standard=>params[:standard]})
    end
    product.update_attributes(parms)
  end

  def update_prod
    update_product("PRODUCT",Product.find(params[:id]))
    redirect_to "/stores/#{params[:store_id]}/products"
  end

  def show_serv
    @serv=Product.find(params[:id])
    @mats=Material.find_by_sql("select name from materials m inner join prod_mat_relations p on
        p.material_id=m.id  where p.product_id=#{@serv.id} and store_id=#{@serv.store_id}").map(&:name).join("  ")
  end

  def add_serv
    @service=Product.new
  end

  def edit_serv
    @service=Product.find(params[:id])
    @materials =ProdMatRelation.find_by_sql("select m.name,s.material_num,m.id from materials m inner join prod_mat_relations s on s.material_id=m.id
      where s.product_id=#{params[:id]}")
  end

  def serv_update
    update_product("SERVICE",Product.find(params[:id]))
    redirect_to "/stores/#{params[:store_id]}/products/prod_services"
  end

  #加载物料信息
  def load_material
    sql = "select id,name from materials  where  store_id=#{params[:store_id]} and status=#{Material::STATUS[:NORMAL]}"
    sql += " and types=#{params[:mat_types]}" if params[:mat_types] != "" || params[:mat_types].length !=0
    sql += " and name like '%#{params[:mat_name]}%'" if params[:mat_name] != "" || params[:mat_name].length !=0
    @materials=Material.find_by_sql(sql)
  end
end
