#encoding: utf-8
class Store::StationsController < ApplicationController
  layout "role"
  before_filter :sign?
  before_filter :find_store
  
  def index
    @stations = @store.stations.valid.includes(:products).paginate(:page => params[:page] ||= 1, :per_page => Station::PerPage)
  end

  def new
    @station = Station.new
  end
  
  def create
    @station = Station.create({:status => 2,:name => params[:station][:name],:store_id => @store.id})
    if @station.save
      params[:product_ids].each do |p|
        StationServiceRelation.create({:station_id => @station.id, :product_id => p})
      end if params[:product_ids]
      render :successful
    else
      render :failed
    end
  end

  def edit
    @station = Station.find(params[:id])
    @url = "/store/stations/#{params[:id]}"
    @method = :put
  end

  def update
    @station = Station.find(params[:id])
    if @station.update_attributes(params[:station])
      @station.station_service_relations.map(&:destroy)
      params[:product_ids].each do |p|
        StationServiceRelation.create({:station_id => @station.id, :product_id => p})
      end if params[:product_ids]
      render :successful
    else
      render :failed
    end
  end

  def destroy
    @station = Station.find(params[:id])
    @station.status = 4
    @station.save
    redirect_to "/store/stations?store_id=#{@store.id}"
  end

  private
  
  def find_store
    store_id = Staff.find(cookies[:user_id]).store_id
    @store = Store.find(store_id)
  end
end