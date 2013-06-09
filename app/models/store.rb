#encoding: utf-8
class Store < ActiveRecord::Base
  has_many :stations
  has_many :reservations
  has_many :products
  has_many :sales
  has_many :work_orders
  has_many :svc_return_records
  has_many :goal_sales
  has_many :message_records
  has_many :notices
  has_many :package_cards
  has_many :staffs
  has_many :materials
  has_many :suppliers
  has_many :month_scores
  has_many :complaints
  has_many :sv_cards
end
