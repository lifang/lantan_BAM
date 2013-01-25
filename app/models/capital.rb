#encoding: utf-8
class Capital < ActiveRecord::Base
  has_many :car_brands
end
