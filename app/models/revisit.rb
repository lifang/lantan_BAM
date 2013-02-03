#encoding: utf-8
class Revisit < ActiveRecord::Base
  belongs_to :customer
  has_many :revisit_order_relations
  belongs_to :complaint
  
end
