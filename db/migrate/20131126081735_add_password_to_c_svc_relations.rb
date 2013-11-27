class AddPasswordToCSvcRelations < ActiveRecord::Migration
  def change
    add_column :c_svc_relations, :password, :string
  end
end
