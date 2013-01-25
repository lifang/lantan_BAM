#encoding: utf-8
class Reservation < ActiveRecord::Base
  belongs_to :store
  has_many :res_prod_relation
end
