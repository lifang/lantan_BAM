#encoding :utf-8
class SalesController < ApplicationController    #营销管理 -- 活动

  #活动列表
  def index
       @sales=Sale.find_by_sql("select name,s.started_at,s.status,count(o.id) reported_num from sales s left join orders o on s.id=o.sale_id where s.store_id=2  group by s.id order by s.started_at desc ")
  end

  #发布活动
  def create
    
  end
end
