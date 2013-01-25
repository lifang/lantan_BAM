#encoding: utf-8
class Train < ActiveRecord::Base
  has_many :train_staff_relations
end
