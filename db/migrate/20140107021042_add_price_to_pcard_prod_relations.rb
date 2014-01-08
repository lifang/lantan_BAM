class AddPriceToPcardProdRelations < ActiveRecord::Migration
  def change
    add_column :package_cards, :sale_percent, :"decimal(20,16)",:default=>1
  end
end
