class AddPriceToPcardProdRelations < ActiveRecord::Migration
  def change
    add_column :pcard_prod_relations, :price, :"float(20,2)",:default=>0
  end
end
