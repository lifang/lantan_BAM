#encoding: utf-8
class ReturnBacksController < ApplicationController
  layout nil

  def return_info
    render :text=>WorkOrder.update_work_order(request.parameters)
  end

  def return_msg
    message = ""
    begin
      msg = TotalMsg.find params[:id]
      message = msg.attributes.select { |key,value| key =~ /msg[0-9]{1,}/ }.values.join("?") if msg
    rescue
    end
    render :text=>message
  end

end