#encoding: utf-8
class CSvcRelation < ActiveRecord::Base
  has_many :svcard_use_records
  belongs_to :sv_card
  has_many :orders
  belongs_to :customer

  STATUS = {:valid => 1, :invalid => 0}         #1有效的，0无效

  #获取用户的已购买的所有打折卡
  def self.get_customer_discount_cards  customer_id, store_id
    sc = CSvcRelation.find_by_sql(["select sv.id sid, sv.name sname, sv.price sprice from c_svc_relations csr inner join
          sv_cards sv on sv.id=csr.sv_card_id where csr.customer_id=? and csr.status=? and ((sv.store_id=? and sv.use_range=?)or(sv.store_id in (?) and
          sv.use_range=?)) and sv.status=? and sv.types=?", customer_id, CSvcRelation::STATUS[:valid], store_id, SvCard::USE_RANGE[:LOCAL],
        StoreChainsRelation.return_chain_stores(store_id), SvCard::USE_RANGE[:CHAINS], SvCard::STATUS[:NORMAL],
        SvCard::FAVOR[:DISCOUNT]]).uniq
    sv_cards = sc.inject([]){|h,s|
      a = {}
      a[:svid] = s.sid
      a[:svname] = s.sname
      a[:svprice] = s.sprice
      a[:svproducts] = []
      a[:is_new] = 0
      items = SvcardProdRelation.find_by_sql(["select spr.product_discount, p.name, p.id, p.sale_price from svcard_prod_relations spr
            inner join products p on spr.product_id=p.id where spr.sv_card_id=?", s.sid])
      items.each do |i|
        hash = {}
        hash[:pid] = i.id
        hash[:pname] = i.name
        hash[:pprice] = i.sale_price
        hash[:pdiscount] = i.product_discount
        a[:svproducts] << hash
      end
      h << a;
      h
    }
    sv_cards
  end
end
