#encoding: utf-8
class ProductsController < ApplicationController
  # 营销管理 -- 产品
  layout 'sale'

  def index
    @products = Product.paginate_by_sql("select service_code code,name,types,sale_price,id,store_id from products where  store_id in (#{params[:store_id]},1)
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
    @services = Product.paginate_by_sql("select id, service_code code,store_id,name,types,base_price,cost_time,staff_level level1,staff_level_1
    level2 from products where store_id in (#{params[:store_id]},1) and is_service=#{Product::PROD_TYPES[:SERVICE]} and status=#{Product::IS_VALIDATE[:YES]}
    order by created_at asc", :page => params[:page], :per_page => 5)
    @materials={}
    @services.each do |service|
      @materials[service.id]=Material.find_by_sql("select name,code,p.material_num num from materials m inner join prod_mat_relations p on
        p.material_id=m.id  where p.product_id=#{service.id}")
    end
  end   #服务列表

  def serv_create
    set_product("SERVICE")
    redirect_to "/stores/#{params[:store_id]}/products/prod_services"
  end   #添加服务

  def set_product(types)
    parms = {:name=>params[:name],:base_price=>params[:base_price],:sale_price=>params[:sale_price],:description=>params[:desc],
      :types=>params[:prod_types],:status=>Product::IS_VALIDATE[:YES],:introduction=>params[:intro], :store_id=>params[:store_id],
      :is_service=>Product::PROD_TYPES[:"#{types}"],:created_at=>Time.now.strftime("%Y-%M-%d"), :service_code=>"#{types[0]}#{Sale.set_code(3)}"
    }
    product =Product.create(parms)
    if types == "SERVICE"
      product.update_attributes({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2] })
      params[:sale_prod].each do |key,value|
        ProdMatRelation.create(:product_id=>product.id,:material_num=>value,:material_id=>key)
      end if params[:sale_prod]
    else
      product.update_attributes({:standard=>params[:standard]})
    end
    if params[:img_url] and !params[:img_url].keys.blank?
      params[:img_url].each {|key,img| ImageUrl.create(:product_id=>product.id,:img_url=>Sale.upload_img(img,product.id,"#{types.downcase}_pics",product.store_id,key))}
    end
  end   #为新建产品或者服务提供参数

  def edit_prod
    @product=Product.find(params[:id])
    @img_urls=@product.image_urls
  end

  def show_prod
    @product =Product.find(params[:id])
    @img_urls = @product.image_urls
  end

  def update_product(types,product)
    parms = {:name=>params[:name],:base_price=>params[:base_price],:sale_price=>params[:sale_price],:description=>params[:desc],
      :types=>params[:prod_types],:introduction=>params[:intro]
    }
    if types == "SERVICE"
      parms.merge!({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2] })
      if params[:sale_prod]
        product.prod_mat_relations.inject(Array.new) {|arr,mat| mat.destroy}
        params[:sale_prod].each do |key,value|
          ProdMatRelation.create(:product_id=>product.id,:material_num=>value,:material_id=>key)
        end
      end
    else
      parms.merge!({:standard=>params[:standard]})
    end
    if params[:img_url] and !params[:img_url].keys.blank?
      product.image_urls.inject(Array.new) {|arr,mat| mat.destroy}
      params[:img_url].each {|key,img| ImageUrl.create(:product_id=>product.id,:img_url=>Sale.upload_img(img,product.id,"#{types.downcase}_pics",product.store_id,key))}
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
        p.material_id=m.id  where p.product_id=#{@serv.id}").map(&:name).join("  ")
    @img_urls = @serv.image_urls
  end

  def add_serv
    @service=Product.new
  end

  def edit_serv
    @service=Product.find(params[:id])
    @sale_prods =ProdMatRelation.find_by_sql("select m.name,s.material_num num,m.id from materials m inner join prod_mat_relations s on s.material_id=m.id
      where s.product_id=#{params[:id]}")
    @img_urls = @service.image_urls
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

  def show
    @prod =Product.find(params[:id])
    @img_urls = @prod.image_urls
  end
end
