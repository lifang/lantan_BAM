#encoding: utf-8
class Category < ActiveRecord::Base
  has_many :products
  has_many :materials
  TYPES = {:material => 0, :good => 1, :service => 2}     #0物料 1商品中的产品 2商品中的服务
  TYPES_NAME = {0=>"物料",1=>"产品",2=>"服务"}

end
