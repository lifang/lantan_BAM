#encoding: utf-8
class Category < ActiveRecord::Base
  has_many :products
  has_many :materials
  TYPES = {:material => 0, :good => 1, :service => 2,:OWNER =>3,:PAYMENT =>4,:ASSETS =>5}     #0物料 1商品中的产品 2商品中的服务 3 付款类别 4 收款类别 5 资产类别
  TYPES_NAME = {0=>"物料",1=>"产品",2=>"服务",3=>"应收",4=>"应付",5=>"资产"}
  DATA_TYPES = [TYPES[:good],TYPES[:service]]

end
