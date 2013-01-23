class Supplier < ActiveRecord::Base
  attr_accessible :address, :contact, :email, :name, :phone
end
