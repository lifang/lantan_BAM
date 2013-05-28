class AddDateTypesToPackageCards < ActiveRecord::Migration
  def change  #套餐卡增加时间段类型
    add_column :package_cards, :date_types, :integer  #时间类型 分为时间段和有效天数
    add_column :package_cards, :date_month, :integer  #有效天数
  end
end
