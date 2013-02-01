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
  PRODUCT_TYPES = {0 => "汽车清洁用品", 1 => "汽车美容用品", 2 => "汽车装饰产品", 3 => "汽车配件产品", 4 => "汽车电子产品",
    5 => "清洗服务", 6 => "维修服务", 7 => "钣喷服务", 8 => "美容服务", 9 => "安装服务"} #产品类别
  PROD_TYPES = {:PRODUCT =>0,:SERVICE =>1}  #0 为产品 1 为服务
  IS_VALIDATE={:NO=>0,:YES=>1} #0 无效 已删除状态 1 有效
end
