#encoding: utf-8
class Complaint < ActiveRecord::Base
has_many :revisits
belongs_to :order
belongs_to :customer
end
