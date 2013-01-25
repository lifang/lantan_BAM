#encoding: utf-8
class Product < ActiveRecord::Base
  has_many :sale_prod_relations
  has_many :res_prod_relations
  has_many :station_service_relations
end
