class AddPropertyToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :property, :integer, :default => 0 #客户属性 个人/集团客户
    add_column :customers, :group_name, :string #集团名称(如果是集团客户)
    add_column :customers, :allowed_debts, :integer, :default => 0 #是否允许欠账
    add_column :customers, :debts_money, :float #欠账额度
    add_column :customers, :check_type, :integer #结算类型(月/周)
    add_column :customers, :check_time, :integer #结算时间(..月/..周)
  end
end
