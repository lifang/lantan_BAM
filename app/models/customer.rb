#encoding: utf-8
class Customer < ActiveRecord::Base
  has_many :customer_num_relations
  has_many :c_svc_relations
  has_many :revisits, :foreign_key => "user_id"
end
