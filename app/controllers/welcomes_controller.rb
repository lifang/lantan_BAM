#encoding: utf-8
class WelcomesController < ApplicationController
  before_filter :sign?
  before_filter :customer_tips,:material_order_tips

  def index
    store = Store.find_by_id(params[:store_id].to_i)
    cookies[:store_name] = {:value => store.name, :path => "/", :secure => false} if store
    render :index, :layout => false
  end
end
