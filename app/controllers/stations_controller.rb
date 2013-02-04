#encoding: utf-8
class StationsController < ApplicationController
  # 现场管理 -- 施工现场
  def index
    Station.set_stations(2)
  end
end
