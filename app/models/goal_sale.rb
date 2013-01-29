#encoding: utf-8
class GoalSale < ActiveRecord::Base
  belongs_to :store
  TYPES_NAMES = {1=>"产品",2=>"服务",3=>"卡"}
  TYPES = {:product=>1,:service=>2,:card=>3}
end
