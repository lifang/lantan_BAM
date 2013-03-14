#encoding: utf-8
class StoredCardsController < ApplicationController
  layout "complaint"

  before_filter :get_store

  def index
    @title = 'a'
    @start_at, @end_at = params[:started_at], params[:ended_at]
    started_at_sql = (@start_at.nil? || @start_at.empty?) ? '1 = 1' : "orders.started_at >= '#{@start_at}'"
    ended_at_sql = (@end_at.nil? || @end_at.empty?) ? '1 = 1' : "orders.ended_at <= '#{@end_at}'"

    @orders = Order.includes(:c_svc_relation => :sv_card).
                          where("orders.store_id = #{params[:store_id]}").
                          where(started_at_sql).where(ended_at_sql).
                          where("sv_cards.types = #{SvCard::FAVOR[:value]}")

    @total_price = @orders.sum(:price)
  end

  def daily_consumption_receipt
    @serach_time = params[:serach_time]

    search_time_sql = params[:serach_time] ||= Time.now.strftime("%Y-%m-%d")

    @orders = Order.where("created_at <= '#{search_time_sql} 23:59:59' and created_at >= '#{search_time_sql} 00:00:00'")

    @current_day_total = Order.where("created_at <= '#{Time.now}' and created_at >= '#{Time.now.strftime("%Y-%m-%d")} 00:00:00'").sum(:price)

    @search_total = @orders.sum(:price)
  end

  def stored_card_bill
    @start_at, @end_at = params[:started_at], params[:ended_at]
    started_at_sql = (@start_at.nil? || @start_at.empty?) ? '1 = 1' : "orders.started_at >= '#{@start_at}'"
    ended_at_sql = (@end_at.nil? || @end_at.empty?) ? '1 = 1' : "orders.ended_at <= '#{@end_at}'"

    @orders = Order.includes(:c_svc_relation => :sv_card).
                          where("orders.store_id = #{params[:store_id]}").
                          where(started_at_sql).where(ended_at_sql).
                          where("sv_cards.types = #{SvCard::FAVOR[:value]}")

    svc_return_records = @orders.collect{|order|SvcReturnRecord.
        where("types = #{SvcReturnRecord::TYPES[:in]} and target_id = #{order.id} and store_id = #{@store.id}").first}
    @total = svc_return_records.sum(&:total_price) - svc_return_records.sum(&:price)

  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
end
