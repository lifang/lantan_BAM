#encoding: utf-8
class WorkRecordsController < ApplicationController
  before_filter :sign?
  layout "staff"

  before_filter :get_store
  
  def index
    @staffs = @store.staffs.not_deleted.select('staffs.name, staffs.type_of_w, staffs.level, staffs.id').
      where("staffs.type_of_w != #{Staff::S_COMPANY[:BOSS]}").
      paginate(:page => params[:page] ||= 1, :per_page => Constant::PER_PAGE)
      
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
end