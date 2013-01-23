class Store < ActiveRecord::Base
  attr_accessible :account, :address, :contact, :email, :img_url, :introduction, :name, :opened_at, :phone, :position
end
