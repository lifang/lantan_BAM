#encoding: utf-8
class CSvcRelation < ActiveRecord::Base
 has_many :svcard_use_records
 belongs_to :sv_card
 has_many :orders
 belongs_to :customer

  STATUS = {:valid => 1, :invalid => 1}         #1有效的，0无效
end
