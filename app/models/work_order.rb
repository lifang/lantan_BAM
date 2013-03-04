#encoding: utf-8
class WorkOrder < ActiveRecord::Base
  belongs_to :station
  belongs_to :order
  belongs_to :store
  STATUS = {0=>"等待服务中",1=>"服务中",2=>"等待付款",3=>"已完成"}
  STAT = {:WAIT=>0,:SERVICING=>1,:WAIT_PAY=>2,:COMPLETE=>3}
end
