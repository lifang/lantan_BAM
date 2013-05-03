#encoding: utf-8
class StationDatasController < ApplicationController
  layout "role"
  before_filter :sign?
  before_filter :find_store

  def index
    @stations = @store.stations.valid.includes(:products).paginate(:page => params[:page] ||= 1, :per_page => Station::PerPage)
  end

  def new
    @action = 'new'
    render :replace_form
  end

  def create
    @station = Station.create({:status => 2,:name => params[:station][:name],:collector_code => params[:station][:collector_code],:store_id => @store.id})
    if @station.save
      if params[:product_ids]
        products = Product.where(:id => params[:product_ids])
        @station.products = products
      end
      render :successful
    else
      render :replace_form
    end
  end

  def edit
    @action = 'edit'
    @station = Station.includes(:products).find(params[:id])
    render :replace_form
  end

  def update
    @station = Station.find(params[:id])
    if @station.update_attributes(params[:station])
      if params[:product_ids]
        products = Product.where(:id => params[:product_ids])
        @station.products = products
      end
      render :successful
    else
      render :replace_form
    end
  end

  def destroy
    @station = Station.find(params[:id])
    @station.status = 4
    redirect_to "/stores/#{@store.id}/station_datas" if @station.save
  end

  private

  def find_store
    store_id = Staff.find(cookies[:user_id]).store_id
    @store = Store.find(store_id)
  end
end