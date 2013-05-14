#encoding: utf-8
class WelcomesController < ApplicationController
  before_filter :sign?
  before_filter :customer_tips,:material_order_tips

  def index
    render :index, :layout => false
  end
end
