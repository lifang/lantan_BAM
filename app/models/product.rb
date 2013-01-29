#encoding: utf-8
class Product < ActiveRecord::Base
  has_many :sale_prod_relations
  has_many :res_prod_relations
  has_many :station_service_relations
  has_many :order_prod_relations
  has_many :pcard_prod_relations
  has_many :prod_mat_relations
  has_many :svcard_prod_relations
  belongs_to :store
  TYPES_NAMES={1=>"清洗服务",2=>"保养服务",3=>"清洗产品",4=>"保养产品"}
   TYPES = {:wash_p=>1,:protect_p=>2,:wash_s=>3,:protect_s=>4}
end
