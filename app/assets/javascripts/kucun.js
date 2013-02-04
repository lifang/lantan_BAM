/**
 * Created with JetBrains RubyMine.
 * User: alec
 * Date: 13-1-28
 * Time: 下午4:44
 * To change this template use File | Settings | File Templates.
 */
function add_material_remark(material_id,remark){
//    alert(material_id);
    $("#remark_div").show();
//    $("#remark").attr("val",remark);
    document.getElementById("remark").innerHTML = remark;
    $("#material_id").attr("value",material_id);
//    alert(remark);
}

function save_material_remark(){
    var m_id = $("#material_id").val();
    var content = $("#remark").val();
    if(m_id!=null && content.length>0){
        $.ajax({
            url:"/materials/"+m_id + "/remark",
            dataType:"json",
            type:"GET",
            data:"remark="+content,
            success: function(data,status){
                if(status == "success"){
                    window.location = location;
                }
            },
            error:function(err){
//                alert(err);
            }
        });
    } else{
        alert("请输入备注内容");
    }
}

function check_material_num(m_id,storage){
    var check_num = $("#check_num_"+m_id).val();
    if(check_num!=storage){
        if(confirm("确定核实的库存？")){
            $.ajax({
                url:"/materials/"+m_id + "/check",
                dataType:"json",
                data:"num="+check_num,
                type:"GET",
                success:function(data,status){
                    if(status=="success"){
                       window.location = location;
                    }
                },
                error:function(){
                    alert("核实失败");
                }
            });
        }
    }
}

function submit_search_form(store_id,type){
    var name = $("#name").val();
    var types = $("#material_types").val();
//    alert(2+"---"+name+"---"+types+"----"+store_id);
    var data = "name="+name+"&types="+types+"&type="+type;
    if(type==1){
        data += "&from=" + $("#from").val();
    }
    $.ajax({
        async:true,
        url:"/stores/"+store_id+"/materials/search",
        dataType:"script",
        data:data,
        type:"GET",
        success:function(){
            $("#search_result").show();
        },error:function(){
            alert("error");
        }
    });
}

function select_material(obj,name,type,panel_type){
//   alert($(obj).val());
   var li = "<li style='list-style-type: none;' id='li_"+$(obj).attr("id")+"'>";
   li += name + "&nbsp;&nbsp;" + type + "&nbsp;&nbsp;" + $(obj).val() + "&nbsp;&nbsp;" +
        "<input type='text' id='out_num_"+$(obj).attr("id")+"' value='1' onchange=\"set_out_num(this,'"+$(obj).val()+"')\" style='width:50px;'/>&nbsp;&nbsp;<a href='javascript:void(0);' onclick='del_result(this)'>删除</a>";
   $("#selected_materials").append(li);
   var select_str = $("#selected_items").val();
   select_str += $(obj).attr("id").split("_")[1] + "_1,";
    $("#selected_items").attr("value",select_str);
}

function select_order_material(obj,name,type,panel_type,code,price){
//   alert($(obj).val());
    var id = $(obj).attr("id").split("_")[1];
    var li = "<li style='list-style-type: none;' id='li_"+$(obj).attr("id")+"'>";
    li += code + "&nbsp;&nbsp;" + name + "&nbsp;&nbsp;" + type + "&nbsp;&nbsp;" + $(obj).val() + "&nbsp;&nbsp;" +  price +
        "&nbsp;&nbsp;<input type='text' id='out_num_"+$(obj).attr("id")+"' value='1' onchange=\"set_order_num(this,'"+$(obj).val()+"','"+id+"','"+price+"')\" style='width:50px;'/>&nbsp;&nbsp;" +
       "<span id='total_"+id+"'>" + price + "</span>&nbsp;&nbsp;<a href='javascript:void(0);' onclick='del_result(this)'>删除</a></li>";
    $("#selected_materials").append(li);
    var select_str = $("#selected_items").val();
    select_str += id + "_1_"+ price +",";
    $("#selected_items").attr("value",select_str);
}

function del_result(obj){
//   alert($("#selected_items").val());
    var select_itemts = $("#selected_items").val().split(",");
    select_itemts = jQuery.grep(select_itemts,function(n,i){
      return select_itemts[i].split("_")[0]!=$(obj).parent().attr("id").split("_")[2];
    });
    $("#selected_items").attr("value",select_itemts.join(","));
//    alert($("#selected_items").val());
    $(obj).parent().remove();
}

function set_out_num(obj,storage){
//  alert($(obj).val()+"---"+storage+"---");
    if(parseInt($(obj).val())>parseInt(storage)){
       alert("请输入小于库存量的值");
    }else if(parseInt($(obj).val())==0){
       alert("请输入出库量");
    }else{
        var select_itemts = $("#selected_items").val().split(",");
        for(var i=0;i<select_itemts.length;i++){
          if(select_itemts[i].split("_")[0]==$(obj).parent().attr("id").split("_")[2]){
             select_itemts[i] = select_itemts[i].split("_")[0] + "_" + $(obj).val();
          }
        }
//        alert(select_itemts);
        $("#selected_items").attr("value",select_itemts.join(","));
    }
}

function set_order_num(obj,storage,m_id,m_price){
//  alert($(obj).val()+"---"+storage+"---");
    $("#total_"+m_id).text(parseInt($(obj).val()) * parseFloat(m_price));
    if(parseInt($(obj).val())>parseInt(storage)){
        alert("请输入小于库存量的值");
    }else if(parseInt($(obj).val())==0){
        alert("请输入出库量");
    }else{
        var select_itemts = $("#selected_items").val().split(",");
        for(var i=0;i<select_itemts.length;i++){
            if(select_itemts[i].split("_")[0]==$(obj).parent().attr("id").split("_")[2]){
                select_itemts[i] = select_itemts[i].split("_")[0] + "_" + $(obj).val() + "_" + select_itemts[i].split("_")[2];
            }
        }
        $("#selected_items").attr("value",select_itemts.join(","));
//        alert($("#selected_items").val());
    }
}

function submit_out_order(form_id){
//    alert($("#selected_items").val());
    if($("#selected_items").val()!=null && $("#selected_items").val()!=""){
        $.ajax({
           url:$("#"+form_id).attr("action"),
           dataType:"json",
           data:"staff="+$("#staff").val()+"&selected_items="+$("#selected_items").val(),
           type:"POST",
           success:function(data,status){
               if(data["status"]==0){
                   alert("出库成功");
               }
           },
           error:function(err){
              alert("出错了");
           }
        });
    }else{
        alert("请选择物料");
    }
}

function add_material(store_id){
  var i = $("#add_new_materials").find("li").size();
  if(i>0){
    i = $("#add_new_materials").find("li").last().attr("id").split("_")[2];
  }
  var li = "<li id='add_li_"+i+"'><input type='text' id='add_barcode_"+i+"'/>&nbsp;&nbsp;<input type='text' id='add_name_"+i+"' />&nbsp;&nbsp;"+
      $("#select_types").html() +"&nbsp;&nbsp;<input type='text' id='add_price_"+i+"'/>&nbsp;&nbsp;<input type='text' id='add_count_"+i+"' />&nbsp;&nbsp;"+
      "<input type='button' value='确定' onclick=\"add_new_material(this,'"+i+"','"+store_id+"')\"/></li>" ;
//    alert(li);
  $("#add_new_materials").append(li);
}

function change_supplier(obj){
    var idx = $(obj).find("option:selected").index();
    $("#search_material").html("");
//    $("#search_result").hide();
    $("#selected_items").attr("value","");
   if(idx == 0){
     $("#selected_materials").html("");
      $("#activity_code").show();
       $("#add_material").hide();
   }else{
       $("#selected_materials").html("");
       $("#activity_code").hide();
       $("#add_material").show();
   }
}

function submit_material_order(form_id){
//    alert($("#selected_items").val());
    if($("#selected_items").val()!=null && $("#selected_items").val()!=""){
        var data = "";
        if(parseInt($("#from").val())==0){
           data = "supplier="+$("#from").val()+"&selected_items="+$("#selected_items").val()+"&use_count="+$("#use_card").attr("value");
            if(document.getElementById("use_code").checked==true){
               data += "&sale_id="+$("#use_code").attr("value");
            }
        }else{
           data = "supplier="+$("#from").val()+"&selected_items="+$("#selected_items").val();
        }
        $.ajax({
            url:$("#"+form_id).attr("action"),
            dataType:"json",
            data:data,
            type:"POST",
            success:function(data,status){
                if(data["status"]==0){
                    alert("订货成功");
                }
            },
            error:function(err){
                alert("出错了");
            }
        });
    }else{
        alert("请选择物料");
    }
}

function delete_supplier(obj,s_id){
  if(confirm("确定要删除供应商？")){
      $.ajax({
          url:window.location.href + "/"+s_id,
          dataType:"json",
          type:"DELETE",
          data:"",
          success:function(data,status){
            if(data.status==1){
                $(obj).parent().remove();
            }

          }
      });
  }
}

function get_act_count(obj){
   if($(obj).val()!=""){
       $.ajax({
           url:"/materials/get_act_count",
           dataType:"json",
           data:"code="+$(obj).val(),
           type:"GET",
           success:function(data,status){
             if(data.status==1){
                $("#use_code_count").text(data.text);
                $("#use_code").attr("value",data.sale_id);
             }
           }
       });
   }
}

function add_new_material(obj,idx,store_id){
//    alert($("#add_barcode_"+idx).val());
   if($("#add_barcode_"+idx).val()==""){
       alert("请输入条形码");
   } else if($("#add_name_"+idx).val()==""){
      alert("请输入名称");
   }else if($("#add_price_"+idx).val()==""){
      alert("请输入单价");
   }else if($("#add_count_"+idx).val()==""){
     alert("请输入订货量");
   }else{
       var item = $("#add_li_"+idx).find("select")[0];
       var type = $(item).find("option:selected").index() + 1;
       $.ajax({
           url:"/stores/" + store_id + "/materials/add",
           dataType:"json",
           type:"POST",
           data:"code="+$("#add_barcode_"+idx).val()+"&name="+$("#add_name_"+idx).val()+"&price="+$("#add_price_"+idx).val() +
           "&count=0&types="+type,
           success:function(data,status){
//              alert(data.material.code);
               var m = data.material;
              add_material_to_selected(data.material,$("#add_count_"+idx).val());
               $("#add_li_"+idx).remove();
           }
       });
   }
}

function add_material_to_selected(obj,count){
//   alert(count);
    var id = obj.id;
    var li = "<li style='list-style-type: none;' id='li_mat_"+id+"'>";
    li += obj.code + "&nbsp;&nbsp;" + obj.name + "&nbsp;&nbsp;" + type_name(obj.types) + "&nbsp;&nbsp;" + obj.storage + "&nbsp;&nbsp;" +
        obj.price + "&nbsp;&nbsp;<input type='text' id='out_num_mat_"+id+"' value='"+count+"' onchange=\"set_order_num(this,'"+obj.storage+"','"+id+"','"+obj.price+"')\" style='width:50px;'/>&nbsp;&nbsp;" +
        "<span id='total_"+id+"'>" + obj.price + "</span>&nbsp;&nbsp;<a href='javascript:void(0);' onclick='del_result(this)'>删除</a></li>";
    $("#selected_materials").append(li);

    var select_str = $("#selected_items").val();
    select_str += id + "_"+count+"_"+ obj.price +",";
    $("#selected_items").attr("value",select_str);
}

function type_name(type){
    name = "";
   if(type==1){
       name = "施工耗材" ;
   }else if(type == 2){
      name = "辅助工具";
   }else if(type==3){
      name = "劳动保护";
   }else if(type==4){
      name = "一次性用品";
   }else if(type==5){
      name = "产品";
   }
    return name;
}