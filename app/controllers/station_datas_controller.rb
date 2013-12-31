#encoding: utf-8
class StationDatasController < ApplicationController
  layout "role"
  before_filter :sign?
  before_filter :find_store

  def index
    @stations = @store.stations.valid.paginate(:page => params[:page] ||= 1, :per_page => Station::PerPage)
  end

  def new
    @categories = Category.where(["types = ? and store_id = ? ", Category::TYPES[:service], @store.id]).inject({}){|hash,c|hash[c.id]=c.name;hash};
    @services = @categories.empty? ? {} : Product.is_normal.where(:category_id => @categories.keys).group_by { |p| p.category_id }
    pack_serv = Product.is_normal.where(:category_id => Product::PACK[:PACK],:store_id=>@store.id)
    unless pack_serv.blank?
      @categories.merge!(Product::PACK_SERVIE)
      @services.merge!(Product::PACK[:PACK]=>pack_serv)
    end
    respond_to do |format|
      format.js
    end
  end

  def create
    name = params[:station_name].strip
    code = params[:station_code].strip
    has_controller = params[:station_has_controller].to_i
    collector_code = params[:station_collector_code].nil? ? nil : params[:station_collector_code].strip
    products = params[:product_ids]
    s = Station.where(["code = ? and store_id = ? and status != ?", code, @store.id, Station::STAT[:DELETED]])
    if s.blank?
      station = Station.new(:name => name, :code => code, :store_id => @store.id, :status => Station::STAT[:NORMAL],
        :is_has_controller => has_controller==0 ? false : true, :collector_code => collector_code)
      if station.save
        products.each do |p|
          StationServiceRelation.create(:station_id => station.id, :product_id => p.to_i)
        end
        @status = 1
      else
        @status = 0
      end
    else
      @status = 2
    end
  end

  def edit
    @station = Station.find_by_id(params[:id].to_i)
    @has_services = @station.products.map(&:id)
    @categories = Category.where(["types = ? and store_id = ? ", Category::TYPES[:service], @store.id]).inject({}){|hash,c|hash[c.id]=c.name;hash};
    @services = @categories.empty? ? {}:Product.is_normal.where(:category_id => @categories.keys).group_by { |p| p.category_id }
    pack_serv = Product.is_normal.where(:category_id => Product::PACK[:PACK],:store_id=>@store.id)
    unless pack_serv.blank?
      @categories.merge!(Product::PACK_SERVIE)
      @services.merge!(Product::PACK[:PACK]=>pack_serv)
    end

    respond_to do |format|
      format.js
    end
  end

  def update
    name = params[:edit_station_name].strip
    code = params[:edit_station_code].strip
    has_controller = params[:edit_station_has_controller].to_i
    collector_code = params[:edit_station_collector_code].nil? ? nil : params[:edit_station_collector_code].strip
    products = params[:edit_product_ids]
    id = params[:id].to_i
    s = Station.where(["id != ? and code = ? and store_id = ? and status != ?", id, code, @store.id, Station::STAT[:DELETED]])
    if s.blank?
      station = Station.find_by_id(id)
      if station.update_attributes(:name => name, :code => code, :store_id => @store.id,
          :is_has_controller => has_controller==0 ? false : true, :collector_code => collector_code)
        StationServiceRelation.delete_all(:station_id => id)
        products.each do |p|
          StationServiceRelation.create(:station_id => id, :product_id => p.to_i)
        end
        @status = 1
      else
        @status = 0
      end
    else
      @status = 2
    end
  end

  def destroy
    station = Station.find_by_id(params[:id])
    if station.update_column(:status, Station::STAT[:DELETED])
      @status = 1
    else
      @status = 0
    end
  end

  private

  def find_store
    @store = Store.find_by_id(params[:store_id]) || not_found
  end
end