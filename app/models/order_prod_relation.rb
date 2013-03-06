#encoding: utf-8
class OrderProdRelation < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  
  def self.order_products(orders)
    products = OrderProdRelation.find_by_sql(["select opr.order_id, opr.pro_num, opr.price, p.name
        from order_prod_relations opr left join products p on p.id = opr.product_id
        where opr.order_id in (?)", orders])
    @product_hash = {}
    products.each { |p| @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p }
    return @product_hash
  end

end
