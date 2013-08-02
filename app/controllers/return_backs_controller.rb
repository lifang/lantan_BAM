#encoding: utf-8
class ReturnBacksController < ApplicationController
  layout nil

  def return_info
    render :text=>params[:info]
  end

end