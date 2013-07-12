#encoding: utf-8
class DepotsController < ApplicationController
  layout "role"
  before_filter :sign?
  before_filter :find_store

  def index
    store = find_store
    @depots = store.depots.paginate(:page => params[:page] ||= 1, :per_page => Depot::PerPage)
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def find_store
    @store = Store.find_by_id(params[:store_id]) || not_found
  end
end