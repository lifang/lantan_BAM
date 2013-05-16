class AddVerifyCodeToCSvcRelations < ActiveRecord::Migration
  def change
    add_column :c_svc_relations, :verify_code, :string
  end
end
