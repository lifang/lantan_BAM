#encoding: utf-8
class Order < ActiveRecord::Base
 has_many :order_prod_relations
 has_many :order_pay_types
 has_many :work_orders
 has_many :revisits
 belongs_to :car_num
 belongs_to :c_pcard_relation
 belongs_to :c_svc_relation
 has_many :revisit_order_relations
end
