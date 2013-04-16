#encoding: utf-8
module Constant
  LOCAL_DIR = "#{Rails.root}/public/"
 
  #权限
  ROLES = {
    #客户
    :customers => {
      :name => "客户",
      :show => ["查询",1],
      :create => ["新建客户",2],
      :delete => ["删除客户",4],
      :send_msg =>["发短信",8],
      :revisit => ["回访",16],
      :group_msg => ["群发短信",32],
      :edit => ["编辑客户",64],
      :detail => ["查看客户详细信息", 128],
      :deal_complaint => ["处理投诉",256]
    },
    #库存
    :materials => {
      :name => "库存",
      :in => ["入库",2],
      :out => ["出库",4],
      :dinghuo =>["订货",8],
      :add_supplier => ["添加供应商",16],
      :supplier => ["查看供应商",32],
      :edit_supplier => ["编辑供应商",64],
      :print => ["打印库存清单", 128],
      :check => ["盘点核实",256],
      :cuihuo => ["催货",512],
      :cancel => ["取消订单",1024],
      :pay => ["付款",2048],
      :del_supplier => ["删除供应商",4096],
      :receive => ["确认已收货",8192]
    },
    :staffs => {
      :name => "员工",
      :add_staff => ["新建员工",1],
      :edit_sys_score => ["编辑系统打分",2],
      :detail_staff => ["查看员工详情",4],
      :add_priase => ["新建奖励",8],
      :add_violation => ["新建违规",16],
      :add_train => ["新建培训",32],
      :month_salary => ["本月工资",64],
      :export_salary => ["导出工资列表",128],
      :edit_salary => ["修改工资",256],
      :detail_salary => ["工资详情",512],
      :edit_show_staff => ["编辑查看员工信息",1024],
      :manager_score => ["店长打分",2048],
      :del_salary => ["删除工资",4096],
      :deal_violation => ["处理奖励违规",8192]

    },
    :datas => {
      :name => "统计",
      :add_target => ["制定目标销售额",1],
      :customer => ["查看客户统计",2],
      :storage => ["查看库存统计",4],
      :staff => ["查看员工统计",8],
      :print => ["打印单据",16]
    },
    :stations => {
      :name => "现场",
      :dispatch => ["分配技师",1],
      :video => ["查看现场视频",2]
    },
    :sales => {
      :name => "营销",
      :add_sale => ["添加活动",1],
      :edit_sale => ["修改活动",2],
      :publish => ["发布活动",4],
      :delete => ["删除活动",8],
      :add_product => ["添加产品",16],
      :edit_product => ["编辑产品",32],
      :add_service => ["添加服务",64],
      :edit_service => ["编辑服务",128],
      :add_p_card => ["添加套餐卡",256],
      :edit_p_card => ["编辑套餐卡",512],
      :del_p_card => ["删除套餐卡",1024],
      :show_sale_records => ["查看销售记录",2048]
    },
    :station_datas => {
      :name => "基础数据"
    }
  }

  #上传图片的比例,如需更改请追加，部分已按index引用
  SALE_PICSIZE =[300,230,663,50]
  P_PICSIZE = [50,154,246,300,356]
  C_PICSIZE = [148,154,50]
 
  #角色
  SYS_ADMIN = "1"  #系统管理员
  BOSS = "2" #老板
  MANAGER = "3" #店长
  STAFF = "4" #员工

  #活动code码生成文件路径
  CODE_PATH =  LOCAL_DIR + "code_file.txt"
  LOG_DIR = LOCAL_DIR + "logs/"

  PER_PAGE = 10

  #施工时间（分钟）
  STATION_MIN = 30
  W_MIN = 10 #休息时间
  #催货提醒
  URGE_GOODS_CONTENT = "门店订货提醒，请关注下"


  #  施工现场文件目录
  VIDEO_DIR ="work_videos"

  #发短信url
  MESSAGE_URL = "http://mt.yeion.com"
  USERNAME = "XCRJ"
  PASSWORD = "123456"
  
  #  SERVER_PATH = "http://bam.gankao.co"
  SERVER_PATH = "http://192.168.1.100:3001"
  #  HEAD_OFFICE_API_PATH = "http://headoffice.gankao.co/"
  HEAD_OFFICE_API_PATH = "http://192.168.1.100:3002/"

  HEAD_OFFICE = HEAD_OFFICE_API_PATH + "syncs/upload_file"
  HEAD_OFFICE_REQUEST_ZIP = HEAD_OFFICE_API_PATH + "syncs/is_generate_zip"
  HEAR_OFFICE_IPHOST= HEAD_OFFICE_API_PATH
  PCARD_PICS = "pcard_pics"
  SALE_PICS = "sale_pics"
  #产品和活动的类别  图片名称分别为 product_pics 和service_pics
  PRODUCT = "PRODUCT"
  SERVICE = "SERVICE"
  UNNEED_UPDATE = ['sync','item','model']  #不更新的表
  DATE_START =  "2013-01"
end