class AddApecialServiceTag < ActiveRecord::Migration
  def change
    add_column :products, :commonly_used, :boolean, :default => false  #给服务加标志，服务是否在新的下单系统中显示
  end
end
