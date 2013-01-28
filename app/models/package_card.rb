#encoding: utf-8
class PackageCard < ActiveRecord::Base
  has_many :pcard_prod_relations
  has_many  :c_pcard_relations
  belongs_to :store
end
