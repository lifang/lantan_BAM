#encoding: utf-8
class DataManagesController < ApplicationController
  include MarketManagesHelper
  before_filter :sign?
  layout "complaint", :except => [:daily_consumption_receipt_blank, :stored_card_bill_blank]
  require 'will_paginate/array'

  def index
    session[:date] = params[:date].nil? ? Time.now.strftime("%Y-%m") : params[:date]
  end

end
