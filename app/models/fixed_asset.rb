#encoding: utf-8
class FixedAsset < ActiveRecord::Base
  STATUS = {:NORMAL => 0,:INVALID =>1} #0 正常 1 作废
  STATUS_NAMES = {0=>"正常",1=>"作废"}
end
