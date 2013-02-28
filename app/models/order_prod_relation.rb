#encoding: utf-8
class OrderProdRelation < ActiveRecord::Base
  belongs_to :order
  belongs_to :product

  PAY_TYPES = {:CASH => 0, :CREDIT_CARD => 1, :SV_CARD => 2} #0 现金  1 刷卡  2 储值卡
  PAY_TYPES_NAME = {0 => "现金", 1 => "刷卡", 2 => "储值卡"}

  #是否满意
  IS_PLEASED = {:BAD => 0, :SOSO => 1, :GOOD => 2, :VERY_GOOD => 3}  #0 不满意  1 一般  2 好  3 很好
  IS_PLEASED_NAME = {0 => "不满意", 1 => "一般", 2 => "好", 3 => "很好"}
  
  def self.order_products(orders)
    products = OrderProdRelation.find_by_sql(["select opr.order_id, opr.pro_num, opr.price, p.name
        from order_prod_relations opr left join products p on p.id = opr.product_id
        where opr.order_id in (?)", orders])
    @product_hash = {}
    products.each { |p| @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p }
    return @product_hash
  end

end
