#encoding: utf-8
class Station < ActiveRecord::Base
  has_many :word_orders
  has_many :station_staff_relations
  has_many :station_service_relations
  has_many :w_o_times
  belongs_to :store
end
