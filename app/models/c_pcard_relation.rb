#encoding: utf-8
class CPcardRelation < ActiveRecord::Base
  belongs_to :package_card
  belongs_to :customer
  has_many :orders
  STATUS={:INVALID=>0,:NORMAL=>1} #0 为无效 1 为正常卡
  STATUS_NAME = {false=>"过期",true=>"正常使用"}

  def get_content ids
    prods = self.content.split(",")
    (ids || []).each do |p_id|
      id = p_id.split("=")[0]
      name = p_id.split("=")[1]
      num = p_id.split("=")[2]
      x = 0
      (prods || []).each_with_index do |idx,prod|
        if prod.split("-")[0].to_i = id
          x += 1
          prods[idx] = prod.split("-")[0].to_s + "-" + prod.split("-")[1].to_s + "-" + (prod.split("-")[2].to_i - 1).to_s
        end
      end
      prods << id.to_s + "-" + name + "-" + num.to_s if x == 0
      prods.join(",")
    end
  end

  def get_prod_num p_id
    prods = self.content.split(",")
    num = 0
    (prods || []).each_with_index do |idx,prod|
      if prod.split("-")[0].to_i = p_id
        num = prod.split("-")[2].to_s
      end
    end
    num
  end

  def self.set_content pcard_id
     pcard_prod_relations = PcardProdRelation.find_all_by_package_card_id pcard_id
     content = nil
     content = pcard_prod_relations.collect{|r|
       s = ""
       if r.product
         s += r.product_id.to_s + "-" + r.product.name + "-" + r.product_num.to_s
       end
       s
     }.join(",") if pcard_prod_relations
    content
  end
end
