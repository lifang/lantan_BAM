#encoding: utf-8
class SyncsController < ActionController::Base
  
  def upload_file
    Sync.accept_file(params[:upload])
    render :text=>"success"
  end

end