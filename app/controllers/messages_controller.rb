#encoding: utf-8
class MessagesController < ApplicationController
  layout "customer"
  
  def index
    session[:started_at] = nil
    session[:ended_at] = nil
    session[:is_vip] = nil
    session[:is_visited] = nil
    session[:is_birthday] = nil
    session[:is_time] = "1"
    session[:time] = nil
    session[:is_price] = "1"
    session[:price] = nil
    @store = Store.find(params[:store_id].to_i)
    @customers = Order.get_message_customers(@store.id, (Time.now - 15.days).to_date.to_s, Time.now.to_date.to_s, nil, "1",
      "3", "1", "500", nil, nil)
  end

  def search
    session[:started_at] = params[:started_at]
    session[:ended_at] = params[:ended_at]
    session[:is_vip] = params[:is_vip]
    if params[:is_visited] == "0" or params[:is_visited] == "1"
      session[:is_visited] = params[:is_visited]
      session[:is_birthday] = nil
    elsif params[:is_visited] == "2"
      session[:is_visited] = nil
      session[:is_birthday] = params[:is_visited]
    end
    session[:is_time] = params[:is_time]
    session[:time] = params[:time]
    session[:is_price] = params[:is_price]
    session[:price] = params[:price]
    redirect_to "/stores/#{params[:store_id]}/messages/search_list"
  end

  def search_list
    @store = Store.find(params[:store_id].to_i)
    @customers = Order.get_message_customers(@store.id, session[:started_at], session[:ended_at], session[:is_visited],
      session[:is_time], session[:time], session[:is_price], session[:price], session[:is_vip], session[:is_birthday])
    render "index"
  end

  def create
    unless params[:content].strip.empty? or params[:customer_ids].nil?
      MessageRecord.transaction do
        message_record = MessageRecord.create(:store_id => params[:store_id].to_i, :content => params[:content].strip,
          :status => MessageRecord::STATUS[:NOMAL], :send_at => Time.now)
        customers = Customer.find_all_by_id(params[:customer_ids].split(","))
        customers.each do |customer|
          SendMessage.create(:message_record_id => message_record.id, :customer_id => customer.id, 
            :content => params[:content].strip.gsub("%name%", customer.name), :phone => customer.mobilephone,
            :send_at => Time.now, :status => MessageRecord::STATUS[:NOMAL])
        end
        flash[:notice] = "短信发送成功。"
      end
    end
    redirect_to "/stores/#{params[:store_id]}/messages/search_list"
  end
end
