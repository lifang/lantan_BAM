#encoding: utf-8
class PackageCard < ActiveRecord::Base
  has_many :pcard_prod_relations
  has_many  :c_pcard_relations
  belongs_to :store

  STAT = {:INVALID =>0,:NORMAL =>1}  #0 为失效或删除  1 为正常使用

  #查询卡信息
  def self.search_pcard(store_id,pcard=nil,car_num=nil,c_name=nil,created_at=nil,ended_at=nil)
    sql="select cp.id,c.name,c.mobilephone,p.name p_name,cp.content,n.num,p.price,cp.status from c_pcard_relations cp inner join customers c on c.id=cp.customer_id
    inner join  package_cards p on p.id=cp.package_card_id inner join customer_num_relations  cn on c.id=cn.customer_id inner join car_nums n
    on n.id=cn.car_num_id where p.store_id=#{store_id} and p.status=#{PackageCard::STAT[:NORMAL]}"
    sql += " and p.id=#{pcard}"  unless pcard.nil? || pcard == "" || pcard.length==0
    sql += " and n.num like '%#{car_num}%'"  unless car_num.nil? || car_num == ""  || car_num.length ==0
    sql += " and c.name like '%#{c_name}%'" unless c_name.nil? || c_name == "" || c_name.length == 0
    sql += " and cp.created_at > #{created_at}" unless created_at.nil? || created_at == "" || created_at.length ==0
    sql += " and cp.ended_at < #{ended_at}" unless ended_at.nil? ||  ended_at == "" || ended_at.length == 0
    return CPcardRelation.find_by_sql(sql)
  end
end
