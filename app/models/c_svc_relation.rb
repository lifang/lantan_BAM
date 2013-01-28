#encoding: utf-8
class CSvcRelation < ActiveRecord::Base
 has_many :svcard_use_records
 belongs_to :sv_card
 has_many :orders
 belongs_to :customer
end
