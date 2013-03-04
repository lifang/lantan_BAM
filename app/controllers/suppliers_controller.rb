class SuppliersController < ApplicationController
   layout "storage"

  def index
    @suppliers = Supplier.paginate(:conditions => "status= #{Supplier::STATUS[:normal]} and store_id=#{params[:store_id]}",
                                   :per_page => 10, :page => params[:page])
    respond_to do |f|
      f.html
      f.js
    end
  end

  def new

  end

  def create
    puts params[:store_id],"--------------"
    Supplier.create({
        :name => params[:name],:contact => params[:contact],:phone => params[:phone],
        :email => params[:email],:address => params[:address],:store_id => params[:store_id],
        :status => Supplier::STATUS[:normal]
                    }) if params[:store_id] && params[:name] && params[:contact] && params[:phone]
    redirect_to store_suppliers_path params[:store_id]
  end

  def destroy
     #puts params[:store_id],params[:id]
     supplier = Supplier.find_by_id_and_store_id params[:id],params[:store_id]
     #puts supplier,"----------"
     supplier.update_attribute(:status,Supplier::STATUS[:delete]) if supplier && supplier.status != Supplier::STATUS[:delete]
    render :json => {:status => 1}
  end

  def change
    supplier = Supplier.find_by_id_and_status params[:id], Supplier::STATUS[:normal]
    if supplier
      supplier.update_attributes({
        :name => params[:name],:contact => params[:contact],:phone => params[:phone],
        :email => params[:email],:address => params[:address]
                                 })
    end
    redirect_to store_suppliers_path params[:store_id]
  end

end