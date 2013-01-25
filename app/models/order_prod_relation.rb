#encoding: utf-8
class OrderProdRelation < ActiveRecord::Base
  belongs_to :order
end
