class ChangePriceToSvCards < ActiveRecord::Migration
  change_column :sv_cards, :price, :float
end
