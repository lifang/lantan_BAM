#encoding: utf-8
class SalesController < ApplicationController    #营销管理 -- 活动
  layout 'sale'

  #活动列表
  def index
    @sales=Sale.paginate_by_sql("select s.id,name,s.store_id,s.started_at,s.everycar_times,s.disc_time_types,s.ended_at,s.code,s.status,
    count(o.id) reported_num from sales s left join orders o on s.id=o.sale_id where s.store_id in (#{params[:store_id]},1) and
    s.status !=#{Sale::STATUS[:DESTROY]}  group by s.id order by s.started_at desc ", :page => params[:page], :per_page => 5)
  end

  #
  def new
    @sale=Sale.new
  end

  #创建发布活动
  def create
    pams={:name=>params[:name],:status=>Sale::STATUS[:UN_RELEASE],:car_num=>params[:car_num],:everycar_times=>params[:every_car],
      :created_at=>Time.now.strftime("%Y%M%d"),:introduction=>params[:intro],:discount=>params["disc_"+params[:discount]],
      :store_id=>params[:store_id], :disc_types=>params[:discount],:disc_time_types=>params[:disc_time],
      :code=>Sale.set_code(8),:is_subsidy =>params[:subsidy]
    }
    pams.merge!({:started_at=>params[:started_at],:ended_at=>params[:ended_at]})  if params[:disc_time].to_i == Sale::DISC_TIME[:TIME]
    pams.merge!({:sub_content=>params[:sub_content]}) if params[:subsidy].to_i == Sale::SUBSIDY[:YES]
    sale=Sale.create!(pams)
    if params[:img_url]
      filename=Sale.upload_img(params[:img_url],sale.id,"sale_pics",sale.store_id)
      sale.update_attributes(:img_url=>filename)
    end
    params[:sale_prod].each do |key,value|
      SaleProdRelation.create({:sale_id=>sale.id,:product_id=>key,:prod_num=>value})
    end
    redirect_to "/stores/#{params[:store_id]}/sales"
  end

  #编辑发布活动
  def edit
    @sale=Sale.find(params[:id])
    @sale_prods=SaleProdRelation.find_by_sql("select p.name,s.prod_num num,p.id from sale_prod_relations s inner join products p on s.product_id=p.id
      where s.sale_id=#{params[:id]}")
  end

  #加载产品或服务类别
  def load_types
    sql = "select id,name from products where  store_id=#{params[:store_id]} and status=#{Product::IS_VALIDATE[:YES]}"
    sql += " and types=#{params[:sale_types]}" if params[:sale_types] != "" || params[:sale_types].length !=0
    sql += " and name like '%#{params[:sale_name]}%'" if params[:sale_name] != "" || params[:sale_name].length !=0
    @products=Product.find_by_sql(sql)
  end

  #删除活动
  def delete_sale
    Sale.find(params[:sale_id]).update_attributes(:status=>Sale::STATUS[:DESTROY])
    respond_to do |format|
      format.json {
        render :json=>{:message=>"删除成功"}
      }
    end
  end
  
  #更新活动
  def update_sale
    @sale=Sale.find(params[:id])
    pams={:name=>params[:name],:car_num=>params[:car_num],:everycar_times=>params[:every_car], :introduction=>params[:intro],
      :discount=>params["disc_"+params[:discount]],:is_subsidy =>params[:subsidy], :disc_types=>params[:discount],:disc_time_types=>params[:disc_time]
    }
    pams.merge!({:img_url=>Sale.upload_img(params[:img_url],@sale.id,"sale_pics",@sale.store_id)}) if params[:img_url]
    pams.merge!({:started_at=>params[:started_at],:ended_at=>params[:ended_at]})  if params[:disc_time].to_i == Sale::DISC_TIME[:TIME]
    pams.merge!({:sub_content=>params[:sub_content]}) if params[:subsidy].to_i == Sale::SUBSIDY[:YES]
    @sale.update_attributes(pams)
    @sale.sale_prod_relations.inject(Array.new) {|arr,sale_prod| sale_prod.destroy}
    params[:sale_prod].each do |key,value|
      SaleProdRelation.create({:sale_id=>@sale.id,:product_id=>key,:prod_num=>value})
    end
    redirect_to "/stores/#{params[:store_id]}/sales"
  end

  #发布活动
  def public_sale
    Sale.find(params[:sale_id]).update_attributes(:status=>Sale::STATUS[:RELEASE])
    respond_to do |format|
      format.json {
        render :json=>{:message=>"发布成功"}
      }
    end
  end

  #活动详细页
  def show
    @sale=Sale.find(params[:id])
  end
end
