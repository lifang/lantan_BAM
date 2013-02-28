#encoding: utf-8
class CurrentMonthSalariesController < ApplicationController
  layout "staff"

  before_filter :get_store

  def index
    @staffs = @store.staffs
  end

  def show
    @staff = Staff.find_by_id(params[:id])
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
  
end
