#encoding:utf-8
class SuppliersController < ApplicationController
  layout "storage"
  before_filter :sign?
  before_filter :find_store
  before_filter :find_supplier, :only => [:edit, :update, :destroy]

  def index
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @store.id])
    @suppliers = Supplier.paginate(:conditions => "status= #{Supplier::STATUS[:normal]} and store_id=#{params[:store_id]}",
                                   :per_page => Constant::PER_PAGE, :page => params[:page])
    respond_to do |f|
      f.html
      f.js
    end
  end

  def new
    @supplier = Supplier.new
  end

  def create
    @supplier = Supplier.create(params[:supplier])
    if @supplier.save
      @store.suppliers << @supplier
      flash[:notice] = "供应商创建成功"
      render :success
    else
      flash[:notice] = "供应商创建失败"
      render :new
    end
  end

  def edit
  end

  def update
    if @supplier.update_attributes(params[:supplier])
      flash[:notice] = "供应商编辑成功"
      render :success
    else
      flash[:notice] = "供应商编辑失败"
      render :edit
    end
  end

  def destroy
    @supplier.update_attribute(:status,Supplier::STATUS[:delete]) if @supplier && @supplier.status != Supplier::STATUS[:delete]
    flash[:notice] = "供应商删除成功"
    redirect_to store_suppliers_path @store
  end
  
  private

  def find_store
    @store = Store.find_by_id(params[:store_id]) || not_found
  end

  def find_supplier
    @supplier = Supplier.find_by_id(params[:id]) || not_found
  end

end