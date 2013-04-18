class SuppliersController < ApplicationController
  layout "storage"
  before_filter :sign?
  before_filter :find_record, :only => [:edit, :update, :destroy]

  def index
    @suppliers = Supplier.paginate(:conditions => "status= #{Supplier::STATUS[:normal]} and store_id=#{params[:store_id]}",
                                   :per_page => Constant::PER_PAGE, :page => params[:page])
    respond_to do |f|
      f.html
      f.js
    end
  end

  def new
    @store = Store.find params[:store_id]
    @supplier = Supplier.new
  end

  def create
    @store = Store.find params[:store_id]
    @supplier = Supplier.create(params[:supplier])
    if @supplier.save
      @store.suppliers << @supplier
      render :success
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @supplier.update_attributes(params[:supplier])
      render :success
    else
      render :edit
    end
  end

  def destroy
    @supplier.update_attribute(:status,Supplier::STATUS[:delete]) if @supplier && @supplier.status != Supplier::STATUS[:delete]
    redirect_to store_suppliers_path @store
  end
  
  private

  def find_record
    @store = Store.find params[:store_id]
    @supplier = Supplier.find params[:id]
  end

end