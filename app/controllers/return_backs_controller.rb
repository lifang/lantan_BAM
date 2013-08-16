#encoding: utf-8
class ReturnBacksController < ApplicationController
  layout nil

  def return_info
    return WorkOrder.update_work_order(request.parameters)
  end

end