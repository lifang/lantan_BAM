#encoding: utf-8
class Category < ActiveRecord::Base
  TYPES = {:material => 0, :good => 1, :service => 2}     #0物料 1商品中的产品 2商品中的服务
end
