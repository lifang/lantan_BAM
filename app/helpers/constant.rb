#encoding: utf-8
module Constant
  LOCAL_DIR = "#{Rails.root}/public/"
  #权限
  ROLES = {
    #客户
    :customers => {
      :show => ["查询、显示客户列表",1],
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
      :show => ["查看库存列表",1],
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
      :add_staff => ["新建员工",1],
      :edit_sys_score => ["编辑系统打分",2],
      :detail_staff => ["查看员工详情",4],
      :add_priase => ["新建奖励",8],
      :add_violation => ["新建违规",16],
      :add_train => ["新建培训",32],
      :month_salary => ["本月工资",64],
      :import_salary => ["导出工资列表",128],
      :edit_salary => ["修改工资",256],
      :detail_salary => ["工资详情",512],
      :edit_show_staff => ["编辑查看员工信息",1024],
      :manager_score => ["店长打分",2048],
      :del_salary => ["删除工资",4096],
      :deal_violation => ["处理奖励违规",8192]

    },
    :datas => {
      :add_target => ["制定目标销售额",1],
      :customer => ["查看客户统计",2],
      :sale => ["查看营销统计",4],
      :storage => ["查看库存统计",8],
      :staff => ["查看员工统计",16],
      :print => ["打印单据",32]
    },
    :stations => {
      :show => ["查看现场",1],
      :dispatch => ["分配技师",2],
      :video => ["查看现场视频",4],
      :pay => ["订单支付",8]
    },
    :sales => {
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
    }
  }

  #上传图片的比例
  PIC_SIZE=[50,100,148,300,700]
 
  #角色
  SYS_ADMIN = "1"  #系统管理员
  BOSS = "2" #老板
  MANAGER = "3" #店长
  STAFF = "4" #员工

  #活动code码生成文件路径
  CODE_PATH =  LOCAL_DIR + "code_file.txt"
  LOG_DIR = LOCAL_DIR + "logs/"
  #总店id
  STORE_ID = 1
  PER_PAGE = 20

  #施工时间（分钟）
  STATION_MIN = 30
  W_MIN = 10 #休息时间
  #催货提醒
  URGE_GOODS_CONTENT = "门店订货提醒，请关注下"

  SERVER_PATH = "http://localhost:3000"

  #  施工现场文件目录
  VIDEO_DIR ="work_videos"

  #发短信url
  MESSAGE_URL = "http://mt.yeion.com"
  USERNAME = "XCRJ"
  PASSWORD = "123456"

  HEAD_OFFICE="http://192.168.0.102:3000/syncs/upload_file"
  PCARD_PICS = "pcard_pics"
  SALE_PICS = "sale_pics"
  #产品和活动的类别  图片名称分别为 product_pics 和service_pics
  PRODUCT = "PRODUCT"
  SERVICE = "SERVICE"
end
