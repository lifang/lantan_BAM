#encoding: utf-8
class Train < ActiveRecord::Base
  has_many :train_staff_relations

  TYPES_NAME = {0 => "新员工培训", 1 => "升职培训", 2 => "再教育培训"}
end
