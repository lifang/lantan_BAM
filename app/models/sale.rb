#encoding: utf-8
class Sale < ActiveRecord::Base
  has_many :sale_prod_relations
  belongs_to :store
  
end
