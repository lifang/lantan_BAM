#encoding: utf-8
class Notice < ActiveRecord::Base
  belongs_to :store

  TYPES = {:BIRTHDAY => 0,  :URGE_GOODS => 1, :URGE_PAYMENT => 2} # 0 客户生日 1 催货  2 催款
  STATUS = {:NOMAL => 0, :INVALID => 1} # 0 有效提示  1 无效提示
end
