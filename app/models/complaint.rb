#encoding: utf-8
class Complaint < ActiveRecord::Base
has_many :revisits
belongs_to :order
belongs_to :customer

 TYPES = { :wash=>1,:waxing=>2,:dirt=>3,:inner_wash=>4,:inner_waxing=>5,:polish=>6,:silver=>7,:glass=>8,:accident=>9,
           :service=>10,:rest=>11,:bad=>12,:part=>13,:timeout=>14,:adviser=>15,:technician=>16}
 TYPES_NAMES = {1=>"精洗施工质量",2=>"打蜡施工质量",3=>"去污施工质量",4=>"内饰清洗施工质量",5=>"内饰护理施工质量",
                6=>"抛光施工质量",7=>"镀晶施工质量",8=>"玻璃清洗护理施工质量",9=>"施工事故（施工过程中导致车辆受损）",
                10=>"服务顾问着装或言辞不得体",11=>"休息厅自取茶水或报纸杂志等不完备",12=>"休息厅环境差",13=>"展厅体验不完整",
                14=>"施工等待时间过长",15=>"服务顾问服务态度不好",16=>"美容技师服务态度不好"}
end
