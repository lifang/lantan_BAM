#encoding: utf-8
class Sync < ActiveRecord::Base
  require 'rubygems'
  require 'net/http'
  require "uri"
  require 'openssl'
  require 'net/http/post/multipart'
  require 'zip/zip'
  require 'zip/zipfilesystem'
  require 'open-uri'

  SYNC_STAT = {:COMPLETE =>1,:ERROR =>0}  #生成/压缩/上传更新文件 完成1 报错0


  #发送上传请求
  def self.send_file(store_id,file_url,filename,sync)
    unless sync.sync_status
      flog = File.open(Constant::LOG_DIR+Time.now.strftime("%Y-%m").to_s+".log","a+")
      begin
        query={:store_id=>store_id}
        url = URI.parse Constant::HEAD_OFFICE
        File.open(file_url) do |file|
          req = Net::HTTP::Post::Multipart.new url.path,query.merge!("upload" => UploadIO.new(file, "application/zip", "#{filename}"))
          http = Net::HTTP.new(url.host, url.port)
          if  http.request(req).body == "success"
            sync.update_attributes(:sync_status=>Sync::SYNC_STAT[:COMPLETE])
            flog.write("数据上传成功---#{Time.now}\r\n")
          end
        end
      rescue
        flog.write("数据上传失败---#{Time.now}\r\n")
      end
      flog.close
    end
  end

  #获取目录下的所有文件
  def self.get_dir_list(path)
    #获取目录列表
    list = Dir.entries(path)
    list.delete('.')
    list.delete('..')
    return list
  end

  #将文件压缩进zip
  def self.input_zip(file_path,store_id)
    get_dir_list(file_path).each {|path|  File.delete(file_path+path) if path =~ /.zip/ }
    filename ="#{Time.now.strftime("%Y%m%d")}_#{store_id}.zip"
    Zip::ZipFile.open(file_path+filename, Zip::ZipFile::CREATE) { |zf|
      get_dir_list(file_path).each {|path| zf.file.open(path, "w") { |os| os.write "#{File.open(file_path+path).read}" } }
    }
    return filename
  end




  def self.out_data(store_id)
    path = Constant::LOCAL_DIR
    Dir.mkdir Constant::LOG_DIR  unless File.directory?  Constant::LOG_DIR
    flog = File.open(Constant::LOG_DIR+Time.now.strftime("%Y-%m").to_s+".log","a+")
    sync =Sync.find_by_store_id_and_sync_at(store_id,Time.now.strftime("%Y-%m-%d"))
    sync =Sync.create(:store_id=>store_id,:sync_at=>Time.now.strftime("%Y-%m-%d"),:created_at=>Time.now.strftime("%Y-%m-%d")) if sync.nil?
    dirs=["syncs_datas/","#{Time.now.strftime("%Y-%m").to_s}/","#{Time.now.strftime("%Y-%m-%d").to_s}/"]
    dirs.each_with_index {|dir,index| Dir.mkdir path+dirs[0..index].join   unless File.directory? path+dirs[0..index].join }
    unless sync.data_status
      begin
        models=get_dir_list("#{Rails.root}/app/models")
        is_update = false
        models.each do |model|
          model_name =model.split(".")[0]
          unless model_name==""
            cap = eval(model_name.split("_").inject(String.new){|str,name| str + name.capitalize})
            attrs = cap.where("TO_DAYS(NOW())-TO_DAYS(created_at)=1")
            unless attrs.blank?
              is_update = true
              file = File.open("#{path+dirs.join+model_name}.log","w+")
              file.write("#{cap.column_names.join(";||;")}\n\n|::|")
              file.write("#{attrs.inject(String.new) {|str,attr|
                str+attr.attributes.values.join(";||;").gsub(";||;true;||;",";||;1;||;").gsub(";||;false;||;",";||;0;||;")+"\n\n|::|"}}")
              file.close
            end
          end
        end
        if is_update
          filename =input_zip(path+dirs.join,store_id)
          sync.update_attributes({:data_status=>Sync::SYNC_STAT[:COMPLETE],:zip_name=>filename})
          flog.write("数据更新并压缩成功---#{Time.now}\r\n")
        end
      rescue
        flog.write("数据更新并压缩失败---#{Time.now}\r\n")
      end
    end
    flog.close
    file_name = filename.nil? ? sync.zip_name : filename
    send_file(store_id,path+dirs.join+file_name,file_name,sync) if file_name
  end

  def self.get_zip_file(day=1)
    ip_host = "http://127.0.0.1:3000/"
    path = Constant::LOCAL_DIR
    dirs = ["syncs_datas/", "#{Time.now.ago(day).strftime("%Y-%m").to_s}/", "#{Time.now.ago(day).strftime("%Y-%m-%d")}/"]
    read_dirs = ["write_datas/", "#{Time.now.ago(day).strftime("%Y-%m").to_s}/", "#{Time.now.ago(day).strftime("%Y-%m-%d")}/"]
    read_dirs.each_with_index {|dir,index| Dir.mkdir path+read_dirs[0..index].join   unless File.directory? path+read_dirs[0..index].join }
    #Dir.mkdir dirs.join unless File.directory? dirs.join
    file_name = "#{Time.now.ago(day).strftime("%Y%m%d")}.zip"
    File.open(path+read_dirs.join+file_name, 'wb') do |fo|
      fo.print open(ip_host+dirs.join+file_name).read
    end
    output_zip(path+read_dirs.join+file_name)
  end

  def self.output_zip(path)
    Zip::ZipFile.open(path){ |zipFile|
      zipFile.each do |file|
        if file.name.split(".").reverse[0] =="log"
          contents = zipFile.read(file).split("\n\n|::|")
          titles =contents.delete_at(0).split(";||;")
          total_con = []
          cap = eval(file.name.split(".")[0].split("_").inject(String.new){|str,name| str + name.capitalize})
          contents.each do |content|
            hash ={}
            cons = content.split(";||;")
            titles.each_with_index {|title,index| hash[title] = cons[index].nil? ? cons[index] : cons[index].force_encoding("UTF-8")}
            object = cap.new(hash)
            object.id = hash["id"]
            total_con << object
          end
          cap.import total_con
        end
      end
    }
  end
end