#encoding: utf-8
namespace :work_orders do
  desc "update work orders water number and gas number"
  task(:update_gas_and_waters => :environment) do
    p "122333"
    WorkOrder.update_work_order
  end

end