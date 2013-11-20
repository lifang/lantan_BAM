#encoding: utf-8
require "uri"
class LoginsController < ApplicationController
  
  def index
    #if cookies[:user_id]
    #@staff = Staff.find_by_id(cookies[:user_id].to_i)
    #if @staff.nil?
    #render :index, :layout => false
    #else
    #session_role(cookies[:user_id])
    #if has_authority?
    #redirect_to "/stores/#{@staff.store_id}/welcomes"
    #else
    #render :index, :layout => false
    #end
    #end
    #else
    render :index, :layout => false
    #end
    
  end

  def create
    @staff = Staff.find(:first, :conditions => ["username = ? and status in (?)",params[:user_name], Staff::VALID_STATUS])
    if  @staff.nil? or !@staff.has_password?(params[:user_password]) 
      flash.now[:notice] = "用户名或密码错误"
      #redirect_to "/"
      @user_name = params[:user_name]
      render 'index', :layout => false
    elsif @staff.store.nil? || @staff.store.status != Store::STATUS[:OPENED]
      flash.now[:notice] = "用户不存在"
      @user_name = params[:user_name]
      render 'index', :layout => false
    else
      cookies[:user_id]={:value =>@staff.id, :path => "/", :secure  => false}
      cookies[:user_name]={:value =>@staff.name, :path => "/", :secure  => false}
      session_role(cookies[:user_id])
      #if has_authority?
      redirect_to "/stores/#{@staff.store_id}/welcomes"
      #else
      #  cookies.delete(:user_id)
      #  cookies.delete(:user_name)
      #  cookies.delete(:user_roles)
      #  cookies.delete(:model_role)
      #  flash[:notice] = "抱歉，您没有访问权限"
      #  redirect_to "/"
      #end
    end
  end

  def logout
    cookies.delete(:user_id)
    cookies.delete(:user_name)
    cookies.delete(:user_roles)
    cookies.delete(:model_role)
    cookies.delete(:store_name)
    cookies.delete(:store_id)
    redirect_to root_path
  end

  def forgot_password
    staff = Staff.where("phone = '#{params[:telphone]}' and validate_code = '#{params[:validate_code]}'").
      where("status in (?)", Staff::VALID_STATUS).first
    if staff && !params[:validate_code].nil? && !params[:validate_code].blank?
      
      random_password = [*100000..999999].sample
      content = "新密码#{random_password}"
      MessageRecord.transaction do
        message_record = MessageRecord.create(:store_id => staff.store_id, :content => content,
          :status => MessageRecord::STATUS[:SENDED], :send_at => Time.now)
        SendMessage.create(:message_record_id => message_record.id, :customer_id => staff.id,
          :content => content, :phone => staff.phone,
          :send_at => Time.now, :status => MessageRecord::STATUS[:SENDED])
        begin
          message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{staff.phone}&Content=#{URI.escape(content)}&Exno=0"
          create_get_http(Constant::MESSAGE_URL, message_route)
        rescue
          @notice = "短信通道忙碌，请稍后重试。"
        end
        staff.password = random_password
        staff.validate_code = nil
        staff.encrypt_password
        staff.save
        @flag = true
        @notice = "短信发送成功，新密码已经发送到手机中。"
      end
    else
      @notice = "手机号，验证码不正确"
    end
  end

  def send_validate_code
    #staff = Staff.find_by_phone(params[:telphone])
    staff = Staff.find(:first, :conditions => ["username = ? and status in (?)",params[:telphone], Staff::VALID_STATUS])
    if staff
      random_num = [*100000..999999].sample
      content = "验证码#{random_num}"
      MessageRecord.transaction do
        message_record = MessageRecord.create(:store_id => staff.store_id, :content => content,
          :status => MessageRecord::STATUS[:SENDED], :send_at => Time.now)
        SendMessage.create(:message_record_id => message_record.id, :customer_id => staff.id,
          :content => content, :phone => staff.phone,
          :send_at => Time.now, :status => MessageRecord::STATUS[:SENDED])
        begin
          message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{staff.phone}&Content=#{URI.escape(content)}&Exno=0"
          create_get_http(Constant::MESSAGE_URL, message_route)
        rescue
          render :text => "短信通道忙碌，请稍后重试。"
        end
        staff.update_attribute(:validate_code, random_num)
        render :text => "success"
      end
    else
      render :text => "手机号码不存在!"
    end
  end

  def phone_login
    render :layout=>nil
  end

  def manage_content
    if cookies[:phone_store].nil?
      redirect_to "/phone_login"
    else
      @store = Store.find(cookies[:phone_store])
      if @store && cookies[:phone_store].to_i == @store.id
        session[:time] = (session[:time].nil? || session[:time] != Time.now.strftime("%Y-%m-%d %H")) ?  Time.now.strftime("%Y-%m-%d %H") :  session[:time]
        @orders = Order.joins("inner join order_prod_relations op on op.order_id=orders.id inner join products p on p.id=op.product_id").
          select("sum(op.pro_num*op.price) num,date_format(orders.created_at,'%Y-%m-%d') day,is_service").where(:status=>[Order::STATUS[:BEEN_PAYMENT],Order::STATUS[:FINISHED]]).
          where("date_format(orders.created_at,'%Y-%m-%d') > '#{Time.now.beginning_of_month.strftime('%Y-%m-%d')}' and date_format(orders.created_at,'%Y-%m-%d %H') <= '#{session[:time]}'").
          group("date_format(orders.created_at,'%Y-%m-%d'),is_service").inject(Hash.new){|hash,order|
          hash[order.day].nil? ? hash[order.day]={order.is_service => order.num} : hash[order.day][order.is_service]=order.num;hash}
        weeks = @orders.select{|k,v| k>= Time.now.beginning_of_week.strftime('%Y-%m-%d')}
        @total_week = weeks == {} ? {0=>0,1=>0} : weeks.values.inject(Hash.new){|hash,total|total.each{|k,v|
            hash[k].nil? ? hash[k]=v : hash[k] += v};hash}
        @total_month = @orders == {} ? {0=>0,1=>0} : @orders.values.inject(Hash.new){|hash,total|
          total.each{|k,v| hash[k].nil? ? hash[k]=v : hash[k] += v};hash}
        render :layout=>nil
      else
        redirect_to "/phone_login"
      end
    end
  end

  def login_phone
    @staff = Staff.find(:first, :conditions => ["username = ? and status in (?)",params[:login_name], Staff::VALID_STATUS])
    if  @staff.nil? or !@staff.has_password?(params[:login_pwd])
      flash.now[:notice] = "用户名或密码错误"
      @user_name = params[:login_name]
      msg =0
    elsif @staff.store.nil? || @staff.store.status != Store::STATUS[:OPENED]
      flash.now[:notice] = "用户不存在"
      @user_name = params[:login_name]
      msg = 0
    else
      cookies[:phone_id] ={:value =>@staff.id, :path => "/", :secure  => false}
      cookies[:phone_store]={:value =>@staff.store_id, :path => "/", :secure  => false}
      msg = 1
    end
    render :json=> {:msg=>msg}
  end
end
