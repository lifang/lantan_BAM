class SetStoresController < ApplicationController
  layout "role"
  before_filter :sign?
  def edit
    @store = Store.find_by_id(params[:store_id].to_i)
  end
end