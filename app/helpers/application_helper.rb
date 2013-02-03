#encoding:utf-8
module ApplicationHelper

  def material_types
    types = []
    items = Material::TYPES_NAMES.to_a.each_with_index{|item,idx|
      types[idx] = [item[1],item[0]]
    }
    types
  end

  def from_s store_id
    a = Item.new
    a.id = 0
    a.name = "总部"
    suppliers = [a] + Supplier.all(:select => "s.id,s.name", :from => "suppliers s",
                                   :conditions => "s.store_id=#{store_id}")
    suppliers
  end

end
