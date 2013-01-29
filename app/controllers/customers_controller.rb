#encoding: utf-8
class CustomersController < ApplicationController
  def index
    base_sql = "select c.id, c.name, c.phone, c.is_vip from customers c "
    
  end
end
