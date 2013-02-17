#encoding: utf-8
class SalesController < ApplicationController    #营销管理 -- 活动
  layout 'sale'

  #活动列表
  def index
    @sales=Sale.paginate_by_sql("select name,s.started_at,s.ended_at,s.code,s.status,count(o.id) reported_num from sales s left join orders o on s.id=o.sale_id
    where s.store_id=#{params[:store_id]} and s.status !=#{Sale::STATUS[:DESTROY]}  group by s.id order by s.started_at desc ", :page => params[:page], :per_page => 2)
  end

  #
  def new
    @sale=Sale.new
  end

  #创建发布活动
  def create
    pams={:name=>params[:name],:status=>Sale::STATUS[:UN_RELEASE],:car_num=>params[:car_num],:everycar_times=>params[:every_car],
      :created_at=>Time.now.strftime("%Y%M%d"),:introduction=>params[:intro],:discount=>params[:discount],:store_id=>params[:store_id],
      :disc_types=>params[:disc_types],:img_url=>params[:img_url],:disc_time=>params[:disc_time],:code=>Sale.set_code(8)
    }
    if params[:disc_time]==Sale::DISC_TIME[:time]
      pams.merge!({:started_at=>params[:started_at],:ended_at=>params[:ended_at]})
    end
    sale=Sale.create!(pams)
    params[:sale_prod].each do |key,value|
      SaleProdRelation.create({:sale_id=>sale.id,:product_id=>key,:prod_num=>value})
    end
  end

  #编辑发布活动
  def edit

  end

  #加载产品或服务类别
  def load_types
    sql = "select id,name from products where  store_id=#{params[:store_id]}"
    sql += " and types=#{params[:sale_types]}" if params[:sale_types] != "" || params[:sale_types].length !=0
    sql += " and name like '%#{params[:sale_name]}%'" if params[:sale_name] != "" || params[:sale_name].length !=0
    @products=Product.find_by_sql(sql)
  end
end
