#encoding: utf-8
class OrderPayType < ActiveRecord::Base
 belongs_to :order

  def self.order_pay_types(orders)
    pay_types = OrderPayType.find(:all, :conditions => ["order_id in (?)", orders])
    @order_pay_type = {}
    pay_types.each { |t|
      @order_pay_type[t.order_id].nil? ? @order_pay_type[t.order_id] = "#{OrderProdRelation::PAY_TYPES_NAME[t.pay_type]}" :
        @order_pay_type[t.order_id] += ", #{OrderProdRelation::PAY_TYPES_NAME[t.pay_type]}"
    }
    return @order_pay_type
  end
  
end
