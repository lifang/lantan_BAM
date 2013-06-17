#encoding: utf-8
class OrderProdRelation < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  
  def self.order_products(orders)
    products = OrderProdRelation.find_by_sql(["select opr.order_id, opr.pro_num, opr.price, p.name
        from order_prod_relations opr left join products p on p.id = opr.product_id
        where opr.order_id in (?)", orders])
    @product_hash = {}
    products.each { |p| 
      @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p
    } if products.any?
    pcar_relations = CPcardRelation.find_by_sql(["select cpr.order_id, 1 pro_num, pc.price, pc.name
        from c_pcard_relations cpr inner join package_cards pc
        on pc.id = cpr.package_card_id where cpr.order_id in (?)", orders])
    pcar_relations.each { |p| 
      @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p
    } if pcar_relations.any?
    csvc_relations = CSvcRelation.find_by_sql(["select csr.order_id, 1 pro_num, sc.price, sc.name
        from c_svc_relations csr inner join sv_cards sc
        on sc.id = csr.sv_card_id where csr.order_id in (?)", orders])
    csvc_relations.each { |p|
      @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p
    } if csvc_relations.any?
    return @product_hash
  end

end
