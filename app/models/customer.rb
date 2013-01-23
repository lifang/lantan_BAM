class Customer < ActiveRecord::Base
  attr_accessible :address, :is_vip, :mark, :mobilephone, :name, :other_way, :sex, :sirthday, :status, :types
end
