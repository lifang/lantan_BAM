#encoding: utf-8
class CSvcRelation < ActiveRecord::Base
  has_many :svcard_use_records
  belongs_to :sv_card
  has_many :orders
  belongs_to :customer

  STATUS = {:valid => 1, :invalid => 0}         #1有效的，0无效

  #获取用户的已购买的所有打折卡
  def self.get_customer_discount_cards  customer_id, store_id
    sc = CSvcRelation.find_by_sql(["select sv.id sid, sv.name sname, sv.types stype, sv.price sprice, csr.id csrid from c_svc_relations csr inner join
          sv_cards sv on sv.id=csr.sv_card_id where csr.customer_id=? and csr.status=? and ((sv.store_id=? and sv.use_range=?)or(sv.store_id in (?) and
          sv.use_range=?)) and sv.types=?", customer_id, CSvcRelation::STATUS[:valid], store_id, SvCard::USE_RANGE[:LOCAL],
        StoreChainsRelation.return_chain_stores(store_id), SvCard::USE_RANGE[:CHAINS], SvCard::FAVOR[:DISCOUNT]]).uniq
    sv_cards = sc.inject([]){|h,s|
      a = {}
      a[:csrid] = s.csrid
      a[:svid] = s.sid
      a[:svname] = s.sname
      a[:svprice] = s.sprice
      a[:svtype] = s.stype
      a[:is_new] = 0
      a[:show_price] = 0
      a[:products] = []
      items = SvcardProdRelation.find_by_sql(["select spr.product_discount, p.name, p.id, p.sale_price from svcard_prod_relations spr
            inner join products p on spr.product_id=p.id where spr.sv_card_id=?", s.sid])
      items.each do |i|
        hash = {}
        hash[:pid] = i.id
        hash[:pname] = i.name
        hash[:pprice] = i.sale_price
        hash[:pdiscount] = i.product_discount.to_i*0.1
        hash[:selected] = 1
        a[:products] << hash
      end
      h << a;
      h
    }
    sv_cards
  end

  #获取该用户所有支持某个产品付款的储值卡
  def self.get_customer_supposed_save_cards  customer_id, store_id, p_id
    result = []
    sc = CSvcRelation.find_by_sql(["select csr.id csrid, csr.left_price l_price, sc.id sid, sc.name sname
       from c_svc_relations csr inner join sv_cards sc on csr.sv_card_id=sc.id
      where csr.customer_id=? and csr.status=? and ((sc.store_id=? and sc.use_range=?)or(sc.store_id in (?) and
      sc.use_range=?)) and sc.types=?", customer_id, CSvcRelation::STATUS[:valid], store_id, SvCard::USE_RANGE[:LOCAL],
        StoreChainsRelation.return_chain_stores(store_id), SvCard::USE_RANGE[:CHAINS], SvCard::FAVOR[:SAVE]]).uniq
    category_id = Product.find_by_id(p_id).category_id.to_i
    sc.each do |s|
      spr = SvcardProdRelation.find_by_sv_card_id(s.sid)
      if spr.category_id && spr.category_id.split(",").inject([]){|h, c| h << c.to_i;h }.include?(category_id)
        h = {}
        h[:csrid] = s.csrid
        h[:l_price] = s.l_price
        h[:svid] = s.sid
        h[:svname] = s.sname
        result << h
      end
    end
    return result
  end
end
