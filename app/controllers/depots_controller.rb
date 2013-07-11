#encoding: utf-8
class DepotsController < ApplicationController
  layout "role"
  before_filter :sign?
  before_filter :find_store

  def index
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def find_store
    @store = Store.find_by_id(params[:store_id]) || not_found
  end
end