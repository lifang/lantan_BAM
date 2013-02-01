#encoding: utf-8
class CustomersController < ApplicationController
  before_filter :customer_tips

  def index
    session[:c_types] = nil
    session[:car_num] = nil
    session[:started_at] = nil
    session[:ended_at] = nil
    session[:name] = nil
    session[:phone] = nil
    session[:is_vip] = nil
    @store = Store.find(params[:store_id].to_i)
    @customers = Customer.search_customer(params[:c_types], params[:car_num], params[:started_at], params[:ended_at],
      params[:name], params[:phone], params[:is_vip], params[:page])
  end

  def search
    session[:c_types] = params[:c_types]
    session[:car_num] = params[:car_num]
    session[:started_at] = params[:started_at]
    session[:ended_at] = params[:ended_at]
    session[:name] = params[:name]
    session[:phone] = params[:phone]
    session[:is_vip] = params[:is_vip]
    redirect_to "/stores/#{params[:store_id]}/customers/search_list"
  end

  def search_list
    @store = Store.find(params[:store_id].to_i)
    @customers = Customer.search_customer(session[:c_types], session[:car_num], session[:started_at], session[:ended_at],
      session[:name], session[:phone], session[:is_vip], params[:page])
    render "index"
  end

  def destroy
    @customer = Customer.find(params[:id].to_i)
    @customer.update_attributes(:status => Customer::STATUS[:DELETED])
    redirect_to request.referer
  end

end
