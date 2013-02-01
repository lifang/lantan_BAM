#encoding: utf-8
class SalesController < ApplicationController    #营销管理 -- 活动

  #活动列表
  def index
    @sales=Sale.paginate_by_sql("select name,s.started_at,s.status,count(o.id) reported_num from sales s left join orders o on s.id=o.sale_id 
    where s.store_id=2 and s.status !=#{Sale::STATUS[:destroy]}  group by s.id order by s.started_at desc ", :page => params[:page], :per_page => 5)
    #store_id 为硬写
  end
  
  #发布活动
  def create
    pams={:name=>params[:name],:status=>Sale::STATUS[:un_release],:car_num=>params[:car_num],:everycar_times=>params[:every_car],
      :created_at=>Time.now.strftime("%Y%M%d"),:introduction=>params[:intro],:discount=>params[:discount],:store_id=>2,
      :disc_types=>params[:disc_types],:img_url=>params[:img_url],:disc_time=>params[:disc_time]
    }#store_id 为硬写
    if params[:disc_time]==Sale::DISC_TIME[:time]
      pams.merge!({:started_at=>params[:started_at],:ended_at=>params[:ended_at]})
    end
    sale=Sale.create!(pams)
    params[:sale_prod].each do |key,value|
      SaleProdRelation.create({:sale_id=>sale.id,:product_id=>key,:prod_num=>value})
    end
  end
end
