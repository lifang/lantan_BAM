#encoding: utf-8
class Complaint < ActiveRecord::Base
  has_many :revisits
  belongs_to :order
  belongs_to :customer

  #投诉类型
  TYPES = { :wash => 1, :waxing => 2, :dirt => 3, :inner_wash => 4, :inner_waxing => 5, :polish => 6, :silver => 7, :glass => 8,
    :accident => 9, :technician => 10, :service => 11,:adviser => 12, :rest => 13, :bad => 14, :part => 15, :timeout => 16,
     :technician => 16, :invalid => 17}
         
  TYPES_NAMES = {1 => "精洗施工质量", 2 => "打蜡施工质量", 3 => "去污施工质量", 4 => "内饰清洗施工质量", 5 => "内饰护理施工质量",
    6 => "抛光施工质量", 7 => "镀晶施工质量", 8 => "玻璃清洗护理施工质量", 9 => "施工事故（施工过程中导致车辆受损）",
    10 => "美容技师服务态度不好", 11 => "服务顾问服务态度不好",
    12 => "服务顾问着装或言辞不得体",13 => "休息厅自取茶水或报纸杂志等不完备", 14 => "休息厅环境差",
    15 => "展厅体验不完整", 16 => "施工等待时间过长", 17 => "无效投诉"}

  #投诉状态
  STATUS = {:UNTREATED => 0, :PROCESSED => 1} #0 未处理  1 已处理
  
end
