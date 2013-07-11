class SetStoresController < ApplicationController
  layout "role"
  before_filter :sign?
  def edit
    @store = Store.find_by_id(params[:store_id].to_i)
    @store_city = City.find_by_id(@store.city_id)
    @cities = City.where(["parent_id = ?", @store_city.parent_id]) if @store_city
    @province = City.where(["parent_id = ?", City::IS_PROVINCE])
  end
end