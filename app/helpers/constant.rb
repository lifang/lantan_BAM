#encoding: utf-8
module Constant
  #权限
  ROLES = {
    #客户
    :customer => {
      :name => "客户",
      :show => ["查询、显示客户列表",1],
      :create => ["新建客户",2],
      :modify => ["删除客户",4],
      :set_winner =>["发短信",8],
      :show_info_back => ["回访",16],
      :stop => ["群发短信",32],
      :attend => ["编辑客户",64],
      :import => ["查看客户详细信息", 128]
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
  CODE_PATH="#{Rails.root}/public/code_file.txt"
  #总店id
  STORE_ID = 1

end
