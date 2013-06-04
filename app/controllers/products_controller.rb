#encoding: utf-8
class ProductsController < ApplicationController
  before_filter :sign?
  # 营销管理 -- 产品
  layout 'sale'

  def index
    @products = Product.paginate_by_sql("select service_code code,name,types,sale_price,t_price,base_price,id,store_id from products where  store_id in (#{params[:store_id]},1)
    and is_service=#{Product::PROD_TYPES[:PRODUCT]} and status=#{Product::IS_VALIDATE[:YES]} order by created_at desc", :page => params[:page], :per_page => Constant::PER_PAGE)
  end  #产品列表页

  #新建
  def add_prod
    @product=Product.new
    @materials =Material.find_by_sql( "select id,name,code,storage from materials  where  store_id=#{params[:store_id]} and
              status=#{Material::STATUS[:NORMAL]} and types=#{Material::TYPES[:PRODUCT]}")
  end
  
  def create
    set_product(Constant::PRODUCT)
    redirect_to "/stores/#{params[:store_id]}/products"
  end  #添加产品


  def prod_services
    @services = Product.paginate_by_sql("select id, service_code code,store_id,name,types,base_price,cost_time,t_price,sale_price,staff_level level1,staff_level_1
    level2 from products where store_id in (#{params[:store_id]},1) and is_service=#{Product::PROD_TYPES[:SERVICE]} and status=#{Product::IS_VALIDATE[:YES]}
    order by created_at asc", :page => params[:page], :per_page => Constant::PER_PAGE)
    @materials={}
    @services.each do |service|
      @materials[service.id]=Material.find_by_sql("select name,code,p.material_num num from materials m inner join prod_mat_relations p on
        p.material_id=m.id  where p.product_id=#{service.id}")
    end
  end   #服务列表

  def serv_create
    set_product(Constant::SERVICE)
    redirect_to "/stores/#{params[:store_id]}/products/prod_services"
  end   #添加服务

  def set_product(types)
    parms = {:name=>params[:name],:base_price=>params[:base_price],:sale_price=>params[:sale_price],:description=>params[:intro],
      :types=>params[:prod_types],:status=>Product::IS_VALIDATE[:YES],:introduction=>params[:desc], :store_id=>params[:store_id],:t_price=>params[:t_price],
      :is_service=>Product::PROD_TYPES[:"#{types}"],:created_at=>Time.now.strftime("%Y-%M-%d"), :service_code=>"#{types[0]}#{Sale.set_code(3,"product","service_code")}"
    }
    product =Product.create(parms)
    if types == Constant::SERVICE
      product.update_attributes({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2],
          :deduct_percent=>params[:deduct_percent] })
      params[:sale_prod].each do |key,value|
        ProdMatRelation.create(:product_id=>product.id,:material_num=>value,:material_id=>key)
      end if params[:sale_prod]
    else
      ProdMatRelation.create(:product_id=>product.id,:material_num=>1,:material_id=>params[:prod_material].to_i)
      product.update_attributes({:standard=>params[:standard]})
    end
    begin
      if params[:img_url] and !params[:img_url].keys.blank?
        params[:img_url].each_with_index {|img,index|
          url=Sale.upload_img(img[1],product.id,"#{types.downcase}_pics",product.store_id,Constant::P_PICSIZE,img[0])
          ImageUrl.create(:product_id=>product.id,:img_url=>url)
          product.update_attributes({:img_url=>url}) if index == 0
        }
      end
    rescue
      flash[:notice] ="图片上传失败，请重新添加！"
    end
  end   #为新建产品或者服务提供参数

  def edit_prod
    @product =Product.find(params[:id])
    @img_urls=@product.image_urls
    @materials =Material.find_by_sql( "select id,name,code,storage from materials  where  store_id=#{params[:store_id]} and
              status=#{Material::STATUS[:NORMAL]} and types=#{Material::TYPES[:PRODUCT]}")
   p @material = @product.prod_mat_relations[0]
  end

  def show_prod
    @product =Product.find(params[:id])
    @img_urls = @product.image_urls
  end

  def update_product(types,product)
    parms = {:name=>params[:name],:base_price=>params[:base_price],:sale_price=>params[:sale_price],:description=>params[:intro],
      :types=>params[:prod_types],:introduction=>params[:desc],:t_price=>params[:t_price],
    }
    if types == Constant::SERVICE
      parms.merge!({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2],:deduct_percent=>params[:deduct_percent] })
      if params[:sale_prod]
        product.prod_mat_relations.inject(Array.new) {|arr,mat| mat.destroy}
        params[:sale_prod].each do |key,value|
          ProdMatRelation.create(:product_id=>product.id,:material_num=>value,:material_id=>key)
        end
      end
    else
      product.prod_mat_relations.first.update_attributes(:material_id=>params[:prod_material].to_i) if product.prod_mat_relations.first
      parms.merge!({:standard=>params[:standard]})
    end
    begin
      if params[:img_url] and !params[:img_url].keys.blank?
        product.image_urls.inject(Array.new) {|arr,mat| mat.destroy}
        params[:img_url].each_with_index {|img,index|
          url=Sale.upload_img(img[1],product.id,"#{types.downcase}_pics",product.store_id,Constant::P_PICSIZE,img[0])
          ImageUrl.create(:product_id=>product.id,:img_url=>url)
          product.update_attributes({:img_url=>url}) if index == 0
        }
      end
    rescue
      flash[:notice] ="图片上传失败，请重新添加！"
    end
    product.update_attributes(parms)
  end

  def update_prod
    update_product(Constant::PRODUCT,Product.find(params[:id]))
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
    update_product(Constant::SERVICE,Product.find(params[:id]))
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

  def prod_delete
    @redit = delete_p(Constant::PRODUCT,params[:id],params[:store_id])
  end

  def serve_delete
    @redit = delete_p(Constant::SERVICE,params[:id],params[:store_id])
  end

  def delete_p(types,id,store_id)
    Product.find(id).update_attribute(:status, Product::IS_VALIDATE[:NO])
    if types == Constant::SERVICE
      redit = "/stores/#{store_id}/products/prod_services"
    else
      redit =  "/stores/#{store_id}/products"
    end
    return redit
  end
end
