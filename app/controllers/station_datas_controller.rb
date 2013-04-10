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
      params[:product_ids].each do |p|
        StationServiceRelation.create({:station_id => @station.id, :product_id => p})
      end if params[:product_ids]
      render :successful
    else
      render :replace_form
    end
  end

  def edit
    @action = 'edit'
    @station = Station.find(params[:id])
    render :replace_form
  end

  def update
    @station = Station.find(params[:id])
    if @station.update_attributes(params[:station])
      StationServiceRelation.delete_all("station_id=#{@station.id}")
      @station.station_service_relations.map(&:destroy)
      params[:product_ids].each do |p|
        StationServiceRelation.create({:station_id => @station.id, :product_id => p})
      end if params[:product_ids]
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