#encoding: utf-8
class MonthScore < ActiveRecord::Base
  belongs_to :staff


  def self.sort_order(store_id)
    return Order.find_by_sql("select date_format(created_at,'%Y-%m-%d') day,sum(op.price) price,op.pay_type  from orders o inner join
           order_pay_types op on o.id=op.order_id where store_id=#{store_id} group by date_format(created_at,'%Y-%m-%d'),op.pay_type ")
  end
end
