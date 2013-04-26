class AddModbusInfoToStations < ActiveRecord::Migration
  def change
    add_column :stations, :elec_switch, :boolean #工位配电开关
    add_column :stations, :clean_m_fb, :boolean         #清洗机反馈
    add_column :stations, :gas_t_switch, :boolean #气体流量开关
    add_column :stations, :gas_run_fb, :boolean #空气机运行反馈
    add_column :stations, :gas_error_fb, :boolean #空气机故障反馈
    add_column :stations, :system_error, :boolean #系统报警
    add_column :stations, :is_using, :boolean #工位有效占用
    add_column :stations, :day_hmi, :boolean #工位日hmi复位
    add_column :stations, :month_hmi, :boolean #工位月hmi复位
    add_column :stations, :once_gas_use, :boolean #工位一次使用的气体数量
    add_column :stations, :once_water_use, :boolean #工位一次使用的水数量
    add_column :work_orders, :gas_num, :boolean
    
  end
end
