#encoding: utf-8
class ReturnBacksController < ApplicationController
  layout nil

  def return_info
    dir = "#{Rails.root}/public/logs"
    Dir.mkdir(dir)  unless File.directory?(dir)
    file_path = dir+"/returnBack_#{Time.now.strftime("%Y%m%d")}.log"
    if File.exists? file_path
      file = File.open( file_path,"a")
    else
      file = File.new(file_path, "w")
    end
    file.puts "#{Time.now.strftime('%Y%m%d %H:%M:%S')}   #{request.parameters.to_s}\r\n"
    file.close
    render :text=>WorkOrder.update_work_order(request.parameters)
  end

  def return_msg
    message = ""
    begin
      msg = TotalMsg.find params[:id]
      message = msg.attributes.select { |key,value| key =~ /msg[0-9]{1,}/ && !value.nil? && value != "" }.values.join("?") if msg
    rescue
    end
    render :text=>message
  end

end