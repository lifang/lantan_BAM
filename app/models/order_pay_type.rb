#encoding: utf-8
class OrderPayType < ActiveRecord::Base
  belongs_to :order

  PAY_TYPES = {:CASH => 0, :CREDIT_CARD => 1, :SV_CARD => 2, 
    :PACJAGE_CARD => 3, :SALE => 4, :IS_FREE => 5, :DISCOUNT_CARD => 6} #0 现金  1 刷卡  2 储值卡   3 套餐卡  4  活动优惠  5免单
  PAY_TYPES_NAME = {0 => "现金", 1 => "刷卡", 2 => "储值卡", 3 => "套餐卡", 4 => "活动优惠", 5 => "免单", 6 => "打折卡"}
  
  def self.order_pay_types(orders)
    return OrderPayType.find(:all, :conditions => ["order_id in (?)", orders]).inject(Hash.new){|hash,t|
      hash[t.order_id].nil? ? hash[t.order_id] = [PAY_TYPES_NAME[t.pay_type]] : hash[t.order_id] << PAY_TYPES_NAME[t.pay_type];
      hash[t.order_id]=hash[t.order_id].uniq;hash
    }
  end
  
end
