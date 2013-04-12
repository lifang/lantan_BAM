/**
 * Created with JetBrains RubyMine.
 * User: alec
 * Date: 13-1-28
 * Time: 下午4:44
 * To change this template use File | Settings | File Templates.
 */
function add_material_remark(material_id,remark){
//    alert(material_id);
    show_mask_div("remark_div");
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
            type:"POST",
            data:"remark="+content,
            success: function(data,status){
                if(status == "success"){
                    window.location.reload();
                }
            },
            error:function(err){
//                alert(err);
            }
        });
    } else{
        tishi_alert("请输入备注内容");
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
                       window.location.reload();
                    }
                },
                error:function(){
                    tishi_alert("核实失败");
                }
            });
        }
    }
}

function submit_search_form(store_id,type,obj){
    var form = $(obj).parent().parent().find("#select_types");
    var name = $(obj).parent().parent().find("#name").val();
    var types = $(form).find("#material_types").val();
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
            $("#dinghuo_search_result").show();
        },error:function(){
            tishi_alert("error");
        }
    });
}

function select_material(obj,name,type,panel_type){
    var select_str = $("#selected_items").val();
    if($(obj).is(":checked")){
        var tr = "<tr id='li_"+$(obj).attr("id")+"'><td>";
        tr += name + "</td><td>" + type + "</td><td>" + $(obj).val() + "</td><td>" +
        "<input type='text' id='out_num_"+$(obj).attr("id")+"' value='1' onchange=\"set_out_num(this,'"+$(obj).val()+"')\" style='width:50px;'/></td><td><a href='javascript:void(0);' onclick='del_result(this,\"\")'>删除</a></td></tr>";
        $("#selected_materials").append(tr);
        select_str += $(obj).attr("id").split("_")[1] + "_1,";
        $("#selected_items").attr("value",select_str);
    }
    else{
        
        var selected_str = "";
        $("#selected_items").val("");
        $("#li_"+$(obj).attr("id")).remove();
        $("#selected_materials").find("tr").each(function(){
           selected_str += $(this).attr("id").split("_")[2] + "_1,";
        })
      $("#selected_items").val(selected_str);
      
    }
}
//select_order_material(this,'水枪',       '辅助工具',1,'234234566','2344.0')
function select_order_material(obj,name,type,panel_type,code,price){
//   alert($(obj).is(":checked"));
    if($(obj).is(":checked")){
        var id = $(obj).attr("id").split("_")[1];
        var storage = $("#from").val()==0 ? $(obj).val() : "--";
        var li = "<tr id='li_"+$(obj).attr("id")+"' class='in_mat_selected'><td>";
        li += code + "</td><td>" + name + "</td><td>" + type + "</td><td>" + price +
            "</td><td><input type='text' id='out_num_"+$(obj).attr("id")+"' value='1' onkeyup=\"set_order_num(this,'"+$(obj).val()+"','"+id+"','"+price+"','"+code+"','"+type+"')\" style='width:50px;'/></td><td>" +
            "<span id='total_"+id+"'>" + price + "</span></td><td>" + storage +"</td><td><a href='javascript:void(0);' onclick='del_result(this,\"_dinghuo\")'>删除</a></td></tr>";
        if($("#dinghuo_selected_materials").find("tr.in_mat_selected").length > 0){
            $("#dinghuo_selected_materials").find("tr.in_mat_selected:last").after(li);
        }else{
            $("#dinghuo_selected_materials").prepend(li);
        }
        var select_str = $("#selected_items_dinghuo").val();
        select_str += id + "_1_"+ price + "_"+ code +"_"+ name +"_"+ type +",";
        $("#selected_items_dinghuo").attr("value",select_str);
        var old_total = parseFloat($("#total_count").text());
        $("#total_count").text(old_total + parseFloat(price));
    }else{
        $("#dinghuo_selected_materials").find("#li_"+$(obj).attr("id")).remove();
        var select_items = $("#selected_items_dinghuo").val().split(",");
        var del_item =  jQuery.grep(select_items,function(n,i){
            return select_items[i].split("_")[0]==$(obj).attr("id").split("_")[1];
        });
        select_items = jQuery.grep(select_items,function(n,i){
            return select_items[i].split("_")[0]!=$(obj).attr("id").split("_")[1];
        });
        $("#selected_items_dinghuo").attr("value",select_items.join(","));
        var items = del_item[0].split("_");
        var old_total = parseFloat($("#total_count").text());
        $("#total_count").text((old_total - parseFloat(items[2]) * parseInt(items[1])).toFixed(2));
    }
}

function del_result(obj,type){
//   alert($("#selected_items").val());
    var select_items = $("#selected_items"+type).val().split(",");
    var del_item =  jQuery.grep(select_items,function(n,i){
        return select_items[i].split("_")[0]==$(obj).parent().parent().attr("id").split("_")[2];
    });
    select_items = jQuery.grep(select_items,function(n,i){
      return select_items[i].split("_")[0]!=$(obj).parent().parent().attr("id").split("_")[2];
    });
    $("#selected_items"+type).attr("value",select_items.join(","));
    $(obj).parent().parent().remove();
    if(type=="_dinghuo"){
        var items = del_item[0].split("_");
        var old_total = parseFloat($("#total_count").text());
        $("#total_count").text((old_total - parseFloat(items[2]) * parseInt(items[1])).toFixed(2));
    }
}

function set_out_num(obj,storage){
//  alert($(obj).val()+"---"+storage+"---");
    if(parseInt($(obj).val())>parseInt(storage)){
       tishi_alert("请输入小于库存量的值");
    }else if(parseInt($(obj).val())==0){
       tishi_alert("请输入出库量");
    }else{
        var select_itemts = $("#selected_items").val().split(",");
        for(var i=0;i<select_itemts.length;i++){
          if(select_itemts[i].split("_")[0]==$(obj).parent().parent().attr("id").split("_")[2]){
             select_itemts[i] = select_itemts[i].split("_")[0] + "_" + $(obj).val();
          }
        }
//        alert(select_itemts);
        $("#selected_items").attr("value",select_itemts.join(","));
    }
}

function set_order_num(obj,storage,m_id,m_price,m_code,m_type){
    var old_num = parseFloat($("#total_"+m_id).text());
    var new_num = parseInt($(obj).val()=="" ? 0 : $(obj).val()) * parseFloat(m_price);
    var name = $("#mat_"+m_id).next().text();
    $("#total_"+m_id).text(new_num.toFixed(1));
    if($("#from").val()==0 && parseInt($(obj).val())>parseInt(storage)){
        tishi_alert("请输入小于库存量的值");
    }else if(parseInt($(obj).val())==0 || $(obj).val()==""){
        tishi_alert("请输入订货量");
    }else{
        var select_itemts = $("#selected_items_dinghuo").val().split(",");
        for(var i=0;i<select_itemts.length;i++){
            if(select_itemts[i].split("_")[0]==$(obj).parent().parent().attr("id").split("_")[2]){
                select_itemts[i] = select_itemts[i].split("_")[0] + "_" + $(obj).val() + "_" + select_itemts[i].split("_")[2] + "_" + m_code + "_" + name + "_" + m_type;
            }
        }
        $("#selected_items_dinghuo").attr("value",select_itemts.join(","));
//        alert($("#selected_items").val());
    }
    var old_total = parseFloat($("#total_count").text());
    $("#total_count").text((old_total + new_num - old_num).toFixed(2));
}

function submit_out_order(form_id){
    var a = true;
    $("#selected_materials").find("input").each(function(){
          var storage = parseInt($(this).parent().prev().text());
          if($(this).val() > storage){
              tishi_alert("请输入小于库存量的值");
              a = false;
          }
    })
    if(a){
    if($("#selected_items").val()!=null && $("#selected_items").val()!=""){
        $.ajax({
           url:$("#"+form_id).attr("action"),
           dataType:"json",
           data:"staff="+$("#staff").val()+"&selected_items="+$("#selected_items").val(),
           type:"POST",
           success:function(data,status){
               if(data["status"]==0){
                   tishi_alert("出库成功");
                   window.location.reload();
               }
           },
           error:function(err){
              tishi_alert("出错了");
           }
        });
    }else{
        tishi_alert("请选择物料");
    }
    }
}

function add_material(store_id){
  var i = $("#dinghuo_selected_materials").find("tr").size();
  if(i>0){
    i = $("#dinghuo_selected_materials").find("tr").last().attr("id").split("_")[2];
  }
  var li = "<tr id='add_li_"+i+"'><td><input type='text' id='add_barcode_"+i+"'/></td><td><input type='text' id='add_name_"+i+"' /></td><td>"+
      $("#select_types").html() +"</td><td><input type='text' id='add_price_"+i+"'/></td><td><input type='text' id='add_count_"+i+"' /></td><td>--</td><td>--</td><td>"+
      "<a href=\"javascript:void(0);\" onclick=\"add_new_material(this,'"+i+"','"+store_id+"')\">确定</a></td></tr>" ;
//    alert(li);
  $("#dinghuo_selected_materials").append(li);
}

function change_supplier(obj){
    var idx = $(obj).find("option:selected").index();
    $("#dinghuo_search_material").html("");
//    $("#search_result").hide();
    $("#selected_items_dinghuo").attr("value","");
    $("#total_count").text(0.0);
   if(idx == 0){
     $("#dinghuo_selected_materials").html("");
      $("#activity_code").show();
       $("#add_material").hide();
       $("#add_new_materials").html("");
   }else{
       $("#dinghuo_selected_materials").html("");
       $("#activity_code").hide();
       $("#add_material").show();
   }
}

function submit_material_order(form_id,pay_type){
//    alert($("#selected_items").val());

        var data = "";
        if(parseInt($("#from").val())==0){
           data = "supplier="+$("#from").val()+"&selected_items="+$("#selected_items_dinghuo").val()+"&use_count="+$("#use_card").attr("value");
            if($("#use_code").is(":checked")){
               data += "&sale_id="+$("#use_code").attr("value");
            }
        }else{
           data = "supplier="+$("#from").val()+"&selected_items="+$("#selected_items_dinghuo").val();
        }
        data += "&pay_type="+pay_type;
        $.ajax({
            url:$("#"+form_id).attr("action"),
            dataType:"json",
            data:data,
            type:"POST",
            success:function(data,status){
                if(data["status"]==0){
                    tishi_alert("订货成功");
                    window.location.reload();
                }else if(data["status"]== -1){
//                   alert(data["pay_req"]);
                    window.open(encodeURI(data["pay_req"]),'支付宝','height=768,width=1024,scrollbars=yes,status =yes');
                }
            },
            error:function(err){
                tishi_alert("订货失败");
            }
        });

}

function pay_material_order(pay_type,store_id){
    $.ajax({
        url:"/stores/"+store_id + "/materials/pay_order",
        dataType:"json",
        data:"order_id="+$("#pay_order_id").val()+"&pay_type="+pay_type,
        type:"GET",
        success:function(data,status){
            if(data["status"]==0){
                tishi_alert("支付成功");
                window.location.reload();
            }else if(data["status"]== -1){
//                alert(data["pay_req"]);
                window.open(encodeURI(data["pay_req"]),'支付宝','height=768,width=1024,scrollbars=yes,status =yes');
            }
        },
        error:function(err){
            tishi_alert("支付失败");
        }
    });
}

function confirm_pay(store_id){
    if($("#selected_items_dinghuo").val()!=null && $("#selected_items_dinghuo").val()!=""){
        show_mask_div("fukuan_tab");
        var supplier = $("#from").find("option:selected").text();
        $("#supplier_from").html("订货渠道："+supplier);
        $("#dinghuo_selected_materials tr").each(function(idx,item){
           var tr = "<tr><td>";
            tr += $($(item).find("td")[0]).html()+"</td><td>"+$($(item).find("td")[1]).html()+"</td><td>"+$($(item).find("td")[2]).html();
            tr += "</td><td>" +$($(item).find("td")[3]).html() +"</td><td>"+ $($(item).find("input[type='text']")).val()+"</td><td>"+ $($(item).find("td")[5]).html() +"</td><tr>";
            $("#order_selected_materials").append(tr);
        });
        if($("#from").val()==0){
           $("#mendian_account").show();
        }else{
          $("#mendian_account").hide();
        }
        $("#price_total").html($("#total_count").html());
        $("#dinghuo_tab").hide();
    }else{
        tishi_alert("请选择物料");
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
//                $(obj).parent().parent().remove();
                window.location.reload();
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
       tishi_alert("请输入条形码");
   } else if($("#add_name_"+idx).val()==""){
      tishi_alert("请输入名称");
   }else if($("#add_price_"+idx).val()==""){
      tishi_alert("请输入单价");
   }else if($("#add_count_"+idx).val()==""){
     tishi_alert("请输入订货量");
   }else{
       var item = $("#add_li_"+idx).find("select")[0];
       var type = $(item).find("option:selected").index() + 1;
       var order_count = $("#add_count_"+idx).val();
       $.ajax({
           url:"/stores/" + store_id + "/materials/add",
           dataType:"json",
           type:"POST",
           data:"code="+$("#add_barcode_"+idx).val()+"&name="+$("#add_name_"+idx).val()+"&price="+$("#add_price_"+idx).val() +
           "&count="+$("#add_count_"+idx).val()+"&types="+type,
           success:function(data,status){
//              alert(data.material.code);
               var m = data.material;
              add_material_to_selected(data.material,order_count);
               $("#add_li_"+idx).remove();
           }
       });
   }
}

function add_material_to_selected(obj,order_count){
    var id = obj.id;
    var each_total_price;
    var toatl_account = 0;
    var li = "<tr id='li_mat_"+id+"' class='in_mat_selected'><td>";
    li += obj.code + "</td><td>" + obj.name + "</td><td>" + type_name(obj.types) + "</td><td>" + parseFloat(obj.price) + "</td>"
        + "<td><input type='text' id='out_num_mat_"+id+"' value='"+order_count+"' onkeyup=\"set_order_num(this,'"+obj.storage+"','"+id+"','"+obj.price+"','"+obj.code+"', '"+type_name(obj.types)+"')\" style='width:50px;'/></td><td>" +
        "<span id='total_"+id+"'>" + parseFloat(obj.price * parseInt(order_count)) + "</span></td><td>--</td><td><a href='javascript:void(0);' onclick='del_result(this,\"_dinghuo\")'>删除</a></td></tr>";
    $("#dinghuo_selected_materials").append(li);
    $("#dinghuo_selected_materials").find("tr.in_mat_selected").each(function(){
       each_total_price = parseFloat($(this).find("td span").text());
       toatl_account += each_total_price;
    })
    $("#total_count").text(toatl_account);
    var select_str = $("#selected_items_dinghuo").val();
    select_str += id + "_"+order_count+"_"+ obj.price +",";
    $("#selected_items_dinghuo").attr("value",select_str);
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

function add_supplier(store_id,supplier_id){
    show_mask_div("add_tab_supplier");
   // alert(store_id);
    $("#s_id").attr("value",supplier_id);
    $("#name").attr("value","");
    $("#contact").attr("value","");
    $("#phone").attr("value","");
    $("#email").attr("value","");
    document.getElementById("address").innerHTML = "";
}

function edit_supplier(form_url,name,contact,phone,email,address){
    show_mask_div("add_tab_supplier");
   $("#name").attr("value",name);
   $("#contact").attr("value",contact);
   $("#phone").attr("value",phone);
   if(email != ""){
       $("#email").attr("value",email);
   }
   if(address!=""){
     document.getElementById("address").innerHTML = address;
   }
   $("#s_id").attr("value",form_url);
}

function commit_supplier_form(){
    if($.trim($("#name").val())==""){
        tishi_alert("请输入名称");
    }else if($.trim($("#contact").val())==""){
        tishi_alert("请输入联系人");
    }else if($.trim($("#phone").val())==""){
        tishi_alert("请输入联系电话");
    }else{
        if($("#s_id").val().length==0){
            $("#add_supplier_form").submit();
        }else{
          $("#add_supplier_form").attr("action",$("#s_id").val()).submit();
//          alert($("#add_supplier_form").attr("action"));
        }
    }
}

//弹出层
function show_mask_div(div_id){
    var doc_height = $(document).height();
    var doc_width = $(document).width();
    var layer_height = $("#"+div_id).height();
    var layer_width = $("#"+div_id).width();

    $(".mask").css({
        display:'block',
        height:doc_height
    });
    var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = document.documentElement.clientHeight;//jQuery(document).height();
    var z_layer_height = $(".tab_alert").height();
    
    $("#"+div_id).css("top",(win_height-z_layer_height)/2 + scolltop).css("left",(doc_width-layer_width)/2).show();
    $("#"+div_id +" a.close").click(function(){
        $("#"+div_id).hide();
        $(".mask").hide();
    })
    $(".cancel_btn").click(function(){
        $("#"+div_id).hide();
        $(".mask").hide();
    })
}

function commit_in(){
    if($.trim($("#name").val())==""){
       tishi_alert("请输入物料名称");
    }else if($("#material_types").val()==""){
       tishi_alert("请选择物料类型");
    }
    else if($.trim($("#code").val())==""){
        tishi_alert("请输入订货单号");
    }else if($.trim($("#barcode").val())==""){
        tishi_alert("请输入条形码");
    }else if($.trim($("#price").val())==""){
        tishi_alert("请输入单价");
    }else if($.trim($("#num").val())==""){
        tishi_alert("请输入数量");
    }else{
      var barcode = $.trim($("#barcode").val());
      var mo_code = $.trim($("#code").val());
      var store_id = $("#hidden_store_id").val();
      $.ajax({
           url:"/stores/" + store_id + "/materials/check_nums",
           dataType:"text",
           type:"GET",
           data:{barcode: barcode, mo_code: mo_code, num: $("#num").val()},
           success:function(data){
              if(data=="1")
               {
                   if(confirm("商品入库数目大于订单中的商品数目，仍然要入库吗？")){
                      $("#ruku_tab_form").submit();
                   }else
                      {$("#ruku_tab").hide();
                         $(".mask").hide();
                         return false;
                      }
               }else if(data=="0"){$("#ruku_tab_form").submit();}
               else{
                  tishi_alert("未找到物料或者订单！");
                  return false;
               }
           }
       });
      
    }
}

function ruku(){
    show_mask_div('ruku_tab');
    $("#name").attr("value","");
    $("#code").attr("value","");
    $("#barcode").attr("value","");
    $("#price").attr("value","");
    $("#num").attr("value","");
    var objs = $("#select_types").find("#material_types");
    for(var x=0;x<objs.length;x++){
        $(objs[x]).get(0).selectedIndex = 0;
    }
    return false;
}

function chuku(){
    show_mask_div('chuku_tab');
    $("#selected_materials").html("");
    $("#search_result").hide();
    $("#out_order_form").find("#name").attr("value","");
    var objs = $("#chuku_tab").find("#material_types");
    for(var x=0;x<objs.length;x++){
      $(objs[x]).get(0).selectedIndex = 0;
    }
    $("#selected_items").attr("value","");
}

function dinghuo(){
    show_mask_div("dinghuo_tab");
    $("#dinghuo_selected_materials").html("");
    $("#dinghuo_search_result").hide();
    var objs = $("#dinghuo_tab").find("#material_types");
    for(var x=0;x<objs.length;x++){
        $(objs[x]).get(0).selectedIndex = 0;
    }
    $("#selected_items_dinghuo").attr("value","");
    $("#from").get(0).selectedIndex = 0;
    $("#add_material").hide();
    $("#order_selected_materials").html("");
    $("#activity_code").show();
    $("#add_material").hide();
}

function search_head_order(store_id){
    $.ajax({
        url:"/stores/"+store_id+"/materials/search_head_orders",
        dataType:"script",
        type:"GET",
        data:"from="+$("#date01").val()+"&to="+$("#date02").val()+"&m_status="+$("#select_h_order").val()+"&status="+$("#h_pay_status").val(),
        success:function(){
//           alert(1);
        },
        error:function(){
//            alert("error");
        }
    });
}

function search_supplier_order(store_id){
    $.ajax({
        url:"/stores/"+store_id+"/materials/search_supplier_orders",
        dataType:"script",
        type:"GET",
        data:"from="+$("#date03").val()+"&to="+$("#date04").val()+"&m_status="+$("#select_s_order").val()+"&type=1&status="+$("#s_pay_status").val(),
        success:function(){
//           alert(1);
        },
        error:function(){
//            alert("error");
        }
    });
}

function add_order_remark(order_id,remark){
    show_mask_div("order_remark_div");
    document.getElementById("order_remark").innerHTML = remark;
    $("#material_order_id").attr("value",order_id);
}

function save_order_remark(){
    var m_id = $("#material_order_id").val();
    var content = $("#order_remark").val();
    if(m_id!=null && content.length>0){
        $.ajax({
            url:"/materials/order_remark",
            dataType:"json",
            type:"POST",
            data:"remark="+content+"&order_id="+m_id,
            success: function(data,status){
                if(status == "success"){
                    window.location.reload();
                }
            },
            error:function(err){
//                alert(err);
            }
        });
    } else{
        tishi_alert("请输入备注内容");
    }
}

function cuihuo(order_id,type,store_id){
    $.ajax({
        url:"/stores/"+store_id+"/materials/cuihuo",
        dataType:"json",
        type:"GET",
        data:"order_id="+order_id+"&type="+type,
        success:function(data,status){
           tishi_alert("已催货");
           hide_mask('#mat_order_detail_tab'); 
        },
        error:function(){
//            alert("error");
        }
    });
}

function cancel_order(order_id,type,store_id){
  if(confirm("确认要取消订单吗？")){
      $.ajax({
          url:"/stores/"+store_id+"/materials/cancel_order",
          dataType:"json",
          type:"GET",
          data:"order_id="+order_id+"&type="+type,
          success:function(data,status){
              tishi_alert(data["content"]);
              window.location.reload();
          },
          error:function(){
//              alert("error");
          }
      });
  }
}

function receive_order(order_id,type,store_id){
    $.ajax({
        url:"/stores/"+store_id+"/materials/receive_order",
        dataType:"json",
        type:"GET",
        data:"order_id="+order_id+"&type="+type,
        success:function(data,status){
            tishi_alert(data["content"]);
            window.location.reload();
        },
        error:function(){
//              alert("error");
        }
    });
}

function pay_order(order_id,store_id){
    show_mask_div("zhifu_tab");
    $("#pay_order_id").attr("value",order_id);
}

function show_notice(type){
  if(type == 0){
    $("#m_notice_div").show();
  }else{
      $("#m_notice_div").hide();
  }
}

function close_notice(ids,store_id){
    $.ajax({
        url:"/stores/"+store_id+"/materials/update_notices",
        dataType:"json",
        type:"GET",
        data:"ids="+ids,
        success:function(){
            window.location.reload();
        }
    });
}