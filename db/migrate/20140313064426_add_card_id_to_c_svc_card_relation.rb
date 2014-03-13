class AddCardIdToCSvcCardRelation < ActiveRecord::Migration
  def change
    add_column :c_svc_relations, :card_id, :string
    add_column :c_pcard_relations, :card_id, :string
  end
end
