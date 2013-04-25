class AddModbusInfoToStations < ActiveRecord::Migration
  def change
    add_column :stations, :elec_switch, :boolean #工位配电开关
    add_column :stations, :clean_m_fb, :boolean         #清洗机反馈
    add_column :stations, :gas_t_switch, :boolean #气体流量开关
    add_column :stations, :gas_run_fb, :boolean #空气机运行反馈
    add_column :stations, :gas_error_fb, :boolean #空气机故障反馈
    add_column :stations, :system_error, :boolean #系统报警
    add_column :stations, :is_using, :boolean #工位有些占用
    
  end
end
