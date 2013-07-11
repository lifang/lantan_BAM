#encoding: utf-8
class WelcomesController < ApplicationController
  before_filter :sign?
  before_filter :customer_tips,:material_order_tips, :except => [:edit_store_name]

  def index
    store = Store.find_by_id(params[:store_id].to_i)
    cookies[:store_name] = {:value => store.name, :path => "/", :secure => false} if store
    cookies[:store_id] = {:value => store.id, :path => "/", :secure => false} if store
    render :index, :layout => false
  end

  def edit_store_name
    if Store.where(["id != ? and name = ?", params[:store_id].to_i,params[:name].strip]).blank?
    store = Store.find_by_id(params[:store_id].to_i)
    if store.nil?
      render :json => {:status => 0}
    else
      if store.update_attribute("name", params[:name].strip)
        cookies.delete(:store_name)
        cookies[:store_name] = {:value => store.name, :path => "/", :secure => false}
        render :json => {:status => 1, :new_name => store.name}
      else
        render :json => {:status => 0}
      end
    end
    else
      render :json => {:status => 2}
    end
  end

end
