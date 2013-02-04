class SuppliersController < ApplicationController

  def index
    @suppliers = Supplier.paginate(:conditions => "status= #{Supplier::STATUS[:normal]} and store_id=#{params[:store_id]}",
                                   :per_page => 10, :page => params[:page])
  end

  def new

  end

  def create
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

  def edit
    @supplier = Supplier.find_by_id_and_status params[:id], Supplier::STATUS[:normal]
  end

  def update
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