#encoding: utf-8
class ReturnBacksController < ApplicationController
  layout nil

  def return_info
    render :text=>WorkOrder.update_work_order(request.parameters)
  end

end