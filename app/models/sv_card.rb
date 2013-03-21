#encoding: utf-8
class SvCard < ActiveRecord::Base
  has_many :svcard_prod_relations
  has_many :c_svc_relations

  FAVOR = {:SAVE =>1,:DISCOUNT=>0} #1 储值卡 0 打折卡
end
