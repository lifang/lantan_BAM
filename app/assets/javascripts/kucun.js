/**
 * Created with JetBrains RubyMine.
 * User: alec
 * Date: 13-1-28
 * Time: 下午4:44
 * To change this template use File | Settings | File Templates.
 */
//保存material remark
    var reg1 =  /^\d+$/;
function save_material_remark(mat_id,store_id,obj){
    var content = $("#remark").val();
    if(mat_id!=null && content.length>0){
        $(obj).attr("disabled", "disabled");
        $.ajax({
            url:"/stores/"+store_id+"/materials/"+mat_id + "/remark",
            dataType:"text",
            type:"POST",
            data:"remark="+content,
            success: function(data){
                if(data == "1"){
                   tishi_alert("操作成功！");
                   hide_mask("#remark_div");
                    //window.location.reload();
                }
            },
            error:function(err){
                tishi_alert("出错了");
            }
        });
    } else{
        tishi_alert("请输入备注内容");
    }
}

function check_material_num(m_id, store_id, obj, pandian_flag){                       //核实库存
    var check_num;
    if(pandian_flag=="")
      {check_num = $("#materials_tab_table #check_num_"+m_id).val();}
    else{
       check_num = pandian_flag;
    }
    
    if(check_num.match(reg1)==null){
        tishi_alert("请输入有效数字");
    }else{
        if(confirm("确定核实的库存？")){
            $.ajax({
                url:"/materials/"+m_id + "/check",
                dataType:"json",
                data:{
                    num : check_num, store_id : store_id
                },
                type:"GET",
                success:function(data){
                    if(data.status=="1"){
                        tishi_alert("操作成功")
                       $(obj).parent().siblings(".su").find(".storage").text(check_num);
                       $(obj).parent().siblings(".check_num_field").find('input').val("");
                       $(obj).parent().siblings(".mat_diff").text(0);
                       var l = $("#low_materials_tbody").find("#material"+m_id+"tr").length;  //判断该物料是否已经在缺货信息提示里
                       var message_span = $("span[id='low_materials_span']").length;            //判断是否有缺货提示
                       if(check_num <= data.material_low){      //如果小于预警值，则加上样式,并且在缺货信息提示里加上对应的元素
                        if(message_span<=0){            //如果没有缺货提示，则要加上
                            $("#material_data_box").before("<div class='message'>有<span class='red' id='low_materials_span'>1</span>个物料库存量过低\n\
                                                            <a href='JavaScript:void(0)' onclick='toggle_low_materials(this)'>点击查看</a>\n\
                                                            <div style='display:none;'><table width='100%' border='0' cellspacing='0' cellpadding='0' class='data_tab_table'>\n\
                                                            <thead><tr class='hbg'><td>条形码</td><td>物料名称</td><td>物料类别</td><td>库存状态</td>\n\
                                                            <td>库存量(个)</td><td>成本价</td></tr></thead><tbody id='low_materials_tbody'><tr id='material"+m_id+"tr'>\n\
                                                            <td width='15%'>"+data.material_code+"</td><td>"+data.material_name+"</td><td>"+data.material_type+"</td><td>\n\
                                                            缺货</td><td id='materialstorage"+m_id+"td'>"+data.material_storage+"</td><td>"+
                                                            data.material_price+"</td></tr></tbody></table></div></div>")
                        }else{
                             if(l<=0){    //如果有缺货提示信息栏，但该记录不在缺货信息提示里，则要加上......
                                var low_materials_count = parseInt($("#low_materials_span").text());
                                $("#low_materials_span").text(low_materials_count+1);
                                var class_name = ($("#low_materials_tbody").find("tr:last").attr("class")=="tbg" ? "" : "tbg");
                                $("#low_materials_tbody").append("<tr id='material"+m_id+"tr' class="+class_name+"><td width='15%'>"+data.material_code+"</td><td>"+
                                                        data.material_name+"</td><td>"+data.material_type+"</td><td>缺货</td><td id='materialstorage"+m_id+"td'>"+
                                                        data.material_storage+"</td><td>"+data.material_price+"</td></tr>")
                            }else{      //如果在缺货提示信息里，则直接改数量......
                                $("#materialstorage"+m_id+"td").text(check_num);
                            }

                        }
                         $(obj).parent().parent().find('td:first').removeAttr("class");
                         $(obj).parent().parent().find('td:first').addClass("data_table_error");
                         $(obj).parent().parent().find('.sstatus').text("缺货");
                       }else{                                   //如果大于预警值.....
                            var low_materials_count = parseInt($("#low_materials_span").text());
                            if(l>0){            //如果缺货信息提示里有的话...                       
                            $("#low_materials_span").text(low_materials_count-1);
                            $("#material"+m_id+"tr").remove();
                            $("#low_materials_tbody").find("tr").removeAttr("class");       //重新加上样式
                            $("#low_materials_tbody").find("tr:odd").attr("class", "tbg");
                            }
                            if((low_materials_count-1)==0){
                                $("#low_materials_span").parent().remove();
                            }
                            $(obj).parent().parent().find('td:first').removeClass("data_table_error");
                            $(obj).parent().parent().find('.sstatus').text("存货");
                       }
                    }else{
                        tishi_alert("核实失败")
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
    if(types==""&&name==""){
        tishi_alert("请选择类型或填写名称！");
    }else{
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
                var mat_ids = [];
                $("#dinghuo_selected_materials").find("tr").each(function(){
                    mat_ids.push($(this).attr('id').split('_')[2])
                })
                $("#dinghuo_search_material").find('input').each(function(){
                    var mat_id = $(this).attr('id').split('_')[1];
                    if(mat_ids.indexOf(mat_id)>=0){
                        $(this).attr("checked", 'checked');
                    }
                })
            },
            error:function(){
                tishi_alert("error");
            }
        });
    }
}

function select_material(obj,name,type,panel_type){
    var select_str = $("#selected_items").val();
    if($(obj).is(":checked")){
        var tr = "<tr id='li_"+$(obj).attr("id")+"'><td>";
        tr += name + "</td><td>" + type + "</td><td>" + $(obj).val() + "</td><td>" +
        "<input type='text' id='out_num_"+$(obj).attr("id")+"' value='1' onchange=\"set_out_num(this,'"+$(obj).val()+"')\" style='width:50px;'/></td><td><a href='javascript:void(0);' alt='"+$(obj).attr("id")+"' onclick='del_result(this,\"\")'>删除</a></td></tr>";
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

//打印条形码 搜索
function select_print_material(obj,name,type){
    if($(obj).is(":checked")){
        var tr = "<tr id='li_"+$(obj).attr("id")+"'><td>";
        tr += $(obj).attr("alt") + "</td><td>" +name + "</td><td>" + type + "</td><td>" + $(obj).attr('data-unit') +"</td><td>"+ "<input type='text' class='print_code' alt="+$(obj).attr("alt")+" name='print["+ $(obj).attr('id').split('_')[1] +"][print_code_num]' style='width:60px' />" + "</td><td>" +
        "<a href='javascript:void(0)' class='"+ $(obj).attr("id") +"' onclick='removeRow(this,1); return false;'>移除</a></td>" +"<input type='hidden' name='print["+ $(obj).attr('id').split('_')[1] +"][print_code]' value="+ $(obj).attr('alt') + "></tr>";
        $("#print_code_tab #selected_materials").append(tr);
    }
    else{
        $("#li_"+$(obj).attr("id")).remove();
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
            "<span class='per_total' id='total_"+id+"'>" + price + "</span></td><td>" + storage +"</td><td><a href='javascript:void(0);' alt='"+id+"' onclick='del_result(this,\"_dinghuo\")'>删除</a></td></tr>";
        if($("#dinghuo_selected_materials").find("tr.in_mat_selected").length > 0){
            $("#dinghuo_selected_materials").find("tr.in_mat_selected:last").after(li);
        }else{
            $("#dinghuo_selected_materials").prepend(li);
        }
        var select_str = $("#selected_items_dinghuo").val();
        select_str += id + "_1_"+ price + "_"+ code +"_"+ name +"_"+ type +",";
        $("#selected_items_dinghuo").attr("value",select_str);
        var old_total = parseFloat($("#total_count").text());
        $("#total_count").text((old_total + parseFloat(price)).toFixed(2));
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
    var matId = $(obj).attr('alt');
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
        $("#dinghuo_search_material").find("input").each(function(){
            var mat_id = $(this).attr("id").split("_")[1];
            if(matId == mat_id){
                $(this).attr("checked",false);
            }
        })
        var items = del_item[0].split("_");
        var old_total = parseFloat($("#total_count").text());
        $("#total_count").text((old_total - parseFloat(items[2]) * parseInt(items[1])).toFixed(2));
    }else{
        $("#search_material").find("input").each(function(){
            var mat_id = $(this).attr("id");
            if(matId == mat_id){
                $(this).attr("checked",false);
            }
        })
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
    var new_num = parseFloat($(obj).val()=="" ? 0 : $(obj).val()) * parseFloat(m_price);
    var name = $("#mat_"+m_id).next().text();
    $("#total_"+m_id).text(new_num.toFixed(2));
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
    var total_price = 0;
    $("#dinghuo_selected_materials").find(".per_total").each(function(){
      total_price += parseFloat($(this).text());
    })
   
    $("#total_count").text(total_price.toFixed(2));
}

function submit_out_order(form_id){
    var a = true;
    $("#selected_materials").find("input").each(function(){
          var storage = parseInt($(this).parent().prev().text());
          var name = $(this).parent().parent().find("td:first").text();
          if($(this).val().match(reg1)==null){
            tishi_alert("请输入有效出库量");
            a = false;
          }
          if(parseFloat($(this).val()) > storage){
              tishi_alert("【"+name+"】出库量请输入小于库存量的值");
              a = false;
          }else if(parseFloat($(this).val()) <= 0){
              tishi_alert("【"+name+"】出库量请输入大于0的值");
              a = false;
          }
    })
    if($("#mat_out_types").val()==""){
        tishi_alert("请选择出库类型")
        a = false;
    }
    if(a){
    if($("#selected_items").val()!=null && $("#selected_items").val()!=""){
        $("#"+form_id).find("input[class='confirm_btn']").attr("disabled","disabled");
        $.ajax({
           url:$("#"+form_id).attr("action"),
           dataType:"json",
           data:"staff="+$("#staff").val()+"&selected_items="+$("#selected_items").val()+"&types="+$("#mat_out_types").val(),
           type:"POST",
           success:function(data,status){
               if(data["status"]==0){
                   tishi_alert("出库成功");
                   window.location.reload();
               }
           },
           error:function(err){
              tishi_alert("正在出库...");
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
      "<button onclick=\"return add_new_material(this,'"+i+"','"+store_id+"')\">确定</button></td></tr>" ;
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

function submit_material_order(form_id,obj){
        var data = "";
        if(parseInt($("#from").val())==0){
           data = "supplier="+$("#from").val()+"&selected_items="+$("#selected_items_dinghuo").val()+"&use_count="+$("#use_card").attr("value");
            if($("#use_code").is(":checked")){
               data += "&sale_id="+$("#use_code").attr("value");
            }
        }else{
           data = "supplier="+$("#from").val()+"&selected_items="+$("#selected_items_dinghuo").val();
        }
       $(obj).attr('disabled', 'disabled');
        $.ajax({
            url:$("#"+form_id).attr("action"),
            dataType:"json",
            data:data,
            type:"POST",
            success:function(data,status){
                if(data["status"]==0){
                    $.ajax({
                        url: $("#"+form_id).attr("action") + "_pay",
                        data:{mo_id:data["mo_id"]},
                        dataType:"script",
                        type:"GET",
                        success:function(data){
                          
                        }
                    })
                   
                }
               else{
                    tishi_alert("出错了，订货失败！")
                }
            },
            error:function(err){
                tishi_alert("付款中...");
            }
        });

}

function pay_material_order(parent_id, pay_type,store_id, obj){
    var mo_id = $("#"+parent_id+" #pay_order_id").val();
    var mo_type = $("#"+parent_id+" #pay_order_type").val();
    var if_refresh = $('#final_fukuan_tab #if_refresh').val();
    var total_price = $("#final_price").text();
    var sav_price = $("#sav_price").val();
    var sale_id = $("#sale_id").val();
    var sale_price = $("#sale_price").text();
    $(obj).attr('disabled', 'disabled')
    $.ajax({
        url:"/stores/"+store_id + "/materials/pay_order",
        dataType:"json",
        data:"mo_id="+mo_id+"&pay_type="+pay_type+"&total_price="+total_price+"&sav_price="+sav_price+"&sale_id="+sale_id+"&sale_price="+sale_price,
        type:"GET",
        success:function(data,status){
            if(data["status"]==0){
                tishi_alert("支付成功");
                if(if_refresh=="0"){
                    if(pay_type!=5)
                    {
                        if(mo_type==1)
                        {
                            $("#page_supplier_orders").find("#" + mo_id).find("td:nth-child(8)").text("已付款")
                        }else{
                            $("#page_head_orders").find("#" + mo_id).find("td:nth-child(8)").text("已付款")
                        }
                    }
                    hide_mask("#" + parent_id);
                }
                else{
                    window.location.href = "/stores/"+store_id + "/materials";
                }
            }else if(data["status"]== -1){
                hide_mask("#"+parent_id);
                popup("#alipay_confirm");
                $("#alipay_confirm #pay_order_id").val(mo_id);
                window.open(encodeURI(data["pay_req"]),'支付宝','height=768,width=1024,scrollbars=yes,status =yes');
            }else{
                tishi_alert("出错了，订货失败！")
            }
        },
        error:function(err){
            tishi_alert("支付失败");
        }
    });
}

function confirm_pay(){
    var flag = true;
    $("#dinghuo_selected_materials .in_mat_selected").find("input").each(function(){
        var count = $(this).val();
        var storage = parseInt($(this).parent().next().next().text());
        var mat_name = $(this).parent().prev().prev().prev().text();
        if(count.match(reg1)==null || count==0){
           flag = false;
           tishi_alert("请输入有效数字");
        }else if(parseInt(count) > storage){
            flag = false;
            tishi_alert("【"+mat_name+"】订货量大于库存量")
        }
    })
if(flag){
    if($("#selected_items_dinghuo").val()!=null && $("#selected_items_dinghuo").val()!=""){
        var total_price = $("#total_count").text();
        popup("#fukuan_tab");
        var supplier = $("#from").find("option:selected").text();
        $("#supplier_from").html("订货渠道："+supplier);
        $("#dinghuo_selected_materials tr.in_mat_selected").each(function(idx,item){
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
        $("#dh_price_total").text(total_price);
        $("#dinghuo_tab").hide();
    }else{
        tishi_alert("请选择物料");
    }
    }
}

function get_act_count(obj,mo_id){
    var price_total = parseFloat($("#price_total").text());
    if($(obj).val()!=""){
        $.ajax({
            url:"/materials/get_act_count",
            dataType:"json",
            data:"code="+$(obj).val()+"&mo_id="+mo_id,
            type:"GET",
            success:function(data,status){
                if(data.status==1){
                    $("#use_code_count").text(data.text);
                    $("#sale_id").attr("value",data.sale_id);
                    if(data.text == ""){
                        tishi_alert("当前code不可用")
                    }
                //$("#sale_price").text(data.text);
                 var save_price = 0.0;
    var sale_price = 0.0;
    if($("#use_card").attr('checked')=='checked')
    {
        $('#savecard_price').text($("#sav_price").val()).parent().show();
        save_price = $("#sav_price").val()=="" ? 0.0 : $("#sav_price").val();
    }
  
    if($("#use_code").attr('checked')=='checked'){
        $('#sale_price').text($("#use_code_count").text()).parent().show();
        sale_price = $("#use_code_count").text()=="" ? 0.0 : $("#use_code_count").text();
    }
    var final_price = (price_total - parseFloat(save_price) - parseFloat(sale_price)) > 0 ? (price_total - parseFloat(save_price) - parseFloat(sale_price)) : 0.0
    $("#final_price").text(parseFloat(final_price).toFixed(2));
                }
            }
        });
    }
    else{
        $("#use_code_count").text("");
        $('#sale_price').text("").parent().hide();
        tishi_alert("请输入活动代码")
        $("#use_code").attr('checked',false);
         var save_price = 0.0;
    var sale_price = 0.0;
    if($("#use_card").attr('checked')=='checked')
    {
        $('#savecard_price').text($("#sav_price").val()).parent().show();
        save_price = $("#sav_price").val()=="" ? 0.0 : $("#sav_price").val();
    }

    if($("#use_code").attr('checked')=='checked'){
        $('#sale_price').text($("#use_code_count").text()).parent().show();
        sale_price = $("#use_code_count").text()=="" ? 0.0 : $("#use_code_count").text();
    }
    var final_price = (price_total - parseFloat(save_price) - parseFloat(sale_price)) > 0 ? (price_total - parseFloat(save_price) - parseFloat(sale_price)) : 0.0
    $("#final_price").text(parseFloat(final_price).toFixed(2));
    }
   
}

function use_sale(obj, flag){
    var total_price = parseFloat($("#price_total").text());
    var sav_price = $("#sav_price").val();
    var sal_price = $("#use_code_count").text();
    if($(obj).attr("checked")=="checked"){
        if(flag=='sav'){
            if(sav_price!="")
            {
                $("#savecard_price").text(sav_price);
                $("#savecard_price").parent().show();
            }
            else{
                tishi_alert("请输入抵用金额");
                $(obj).attr("checked", false);
            }
        //$("#price_total").text((total_price - sav_price) > 0 ? (total_price - sav_price) : 0.0);
        }
        else{
            if($("#act_code").val()!=""){
              if(sal_price!=""){
                $("#sale_price").text(sal_price);
                $("#sale_price").parent().show();
                }
            }else{
                tishi_alert("请输入活动代码");
                $(obj).attr("checked", false);
            }
        }
    }
    else{
        if(flag=='sav'){
            $("#savecard_price").text("");
            $("#savecard_price").parent().hide();
        }
        else{
            $("#sale_price").text("");
            $("#sale_price").parent().hide();
           
        }
    }
    if($("#sav_price").val()!="" || sal_price!=""){
        var final_price = parseFloat($("#price_total").text()) - parseFloat($("#sale_price").text()=="" ? 0 : $("#sale_price").text()) - parseFloat($("#savecard_price").text()=="" ? 0 :$("#savecard_price").text())
        $("#final_price").text(final_price < 0 ? "0.0" : parseFloat(final_price).toFixed(2));
    }
}

function add_new_material(obj,idx,store_id){
   if($("#add_barcode_"+idx).val()==""){
       tishi_alert("请输入条形码");
   }else if($("#add_name_"+idx).val()==""){
      tishi_alert("请输入名称");
   }else if($("#add_price_"+idx).val()==""){
      tishi_alert("请输入单价");
   }else if($("#add_count_"+idx).val()==""){
     tishi_alert("请输入订货量");
   }else{
       var item = $("#add_li_"+idx).find("select")[0];
       var type = $(item).find("option:selected").index() + 1;
       var order_count = $("#add_count_"+idx).val();
       $(obj).attr('disabled','disabled');
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
    return false;
}

function add_material_to_selected(obj,order_count){
    var id = obj.id;
    var each_total_price;
    var toatl_account = 0.0;
    var selectedItems = $("#dinghuo_selected_materials").find('#li_mat_'+id);
    var nonchecked = $("#dinghuo_search_material").find("#mat_"+id);
    if(nonchecked.length>0){
        nonchecked.attr("checked", 'checked');
    }
    if(selectedItems.length==0){
    var li = "<tr id='li_mat_"+id+"' class='in_mat_selected'><td>";
    li += obj.code + "</td><td>" + obj.name + "</td><td>" + type_name(obj.types) + "</td><td>" + parseFloat(obj.price) + "</td>"
        + "<td><input type='text' id='out_num_mat_"+id+"' value='"+order_count+"' onkeyup=\"set_order_num(this,'"+obj.storage+"','"+id+"','"+obj.price+"','"+obj.code+"', '"+type_name(obj.types)+"')\" style='width:50px;'/></td><td>" +
        "<span class='per_total' id='total_"+id+"'>" + parseFloat(obj.price * parseInt(order_count)) + "</span></td><td>--</td><td><a href='javascript:void(0);' onclick='del_result(this,\"_dinghuo\")'>删除</a></td></tr>";
    $("#dinghuo_selected_materials").append(li);
    }else{
       var ori_num = selectedItems.find('#out_num_mat_'+id);
       var ori_price = selectedItems.find('#total_'+id);
       ori_num.val(parseInt(ori_num.val())+parseInt(order_count));
       ori_price.text(parseInt(ori_num.val())*parseFloat(obj.price));
    }
    $("#dinghuo_selected_materials").find("tr.in_mat_selected").each(function(){
       each_total_price = parseFloat($(this).find("td span").text());
       toatl_account += each_total_price;
    })
    $("#total_count").text(toatl_account.toFixed(2));
    var select_str = $("#selected_items_dinghuo").val();
    select_str += id + "_"+order_count+"_"+ obj.price +",";
    $("#selected_items_dinghuo").attr("value",select_str);
}

function removeChecked(obj){
    if(parseFloat($(obj).val()) < 0 || $(obj).val()==""){
        tishi_alert("请输入有效抵用款");
        $(obj).val("");
        $("#use_card").attr('checked', false);
        $('#savecard_price').text("").parent().hide()
    }else if(parseFloat($(obj).val()) > parseFloat($("#use_card").val())){
        tishi_alert("请输入小于可使用抵用款");
        $(obj).val("");
        $("#use_card").attr('checked', false);
        $('#savecard_price').text("").parent().hide()
     }
    //else if(parseFloat($(obj).val()) <= parseFloat($("#use_card").val())){
         
   //  }
    var price_total = parseFloat($("#price_total").text());
    var save_price = 0.0;
    var sale_price = 0.0;
    if($("#use_card").attr('checked')=='checked')
      {
        $('#savecard_price').text($(obj).val()).parent().show();
        save_price = $(obj).val()=="" ? 0.0 : $(obj).val();
      }
     if($("#use_code").attr('checked')=='checked'){
        $('#sale_price').text($("#use_code_count").text()).parent().show();
        sale_price = $("#use_code_count").text()=="" ? 0.0 : $("#use_code_count").text();
     }
      var final_price = (price_total - parseFloat(save_price) - parseFloat(sale_price)) > 0 ? (price_total - parseFloat(save_price) - parseFloat(sale_price)) : "0.0"

     $("#final_price").text(parseFloat(final_price).toFixed(2));
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

function commit_supplier_form(obj){
    if($.trim($("#supplier_name").val())==""){
        tishi_alert("请输入名称");
    }else if($.trim($("#supplier_contact").val())==""){
        tishi_alert("请输入联系人");
    }else if($.trim($("#supplier_phone").val())==""){
        tishi_alert("请输入联系电话");
    }else{
       $(obj).parents("form").submit();
       $(obj).attr('disabled','disabled');
    }
}

function checkMaterial(obj){              //编辑物料验证
    var reg2 = /^\d+\.{0,1}\d*$/;
    var pattern = new RegExp("[=,-]")
    var f = true;
  if($.trim($("#material_name").val())==""){
       tishi_alert("请输入物料名称");
       f = false;
    }else if($("#material_name").val().match(pattern)!=null){
        tishi_alert("物料名称不能包含非法字符");
        f = false;
    }
    else if($("#material_div #material_types").val()==""){
        tishi_alert("请输入类型");
        f = false;
    }else if($("#material_price").val().match(reg2)==null){
        tishi_alert("请输入合法单价");
        f = false;
    }else if($("#material_sale_price").val().match(reg2)==null){
        tishi_alert("请输入合法零售价");
        f = false;
    }else if($("#material_unit").val()==""){
        tishi_alert("请输入物料规格");
        f = false;
    }
      if(f){
       $(obj).parents("form").submit();
       $(obj).attr('disabled','disabled'); 
      }else{
          $(obj).attr("disabled", false);
      }
         
}

function commit_in(obj){
    if($.trim($("#name").val())==""){
       tishi_alert("请输入物料名称");
    }else if($("#ruku_tab #material_types").val()==""){
       tishi_alert("请选择物料类型");
    }
    else if($.trim($("#code").val())==""){
        tishi_alert("请输入订货单号");
    }else if($.trim($("#barcode").val())==""){
        tishi_alert("请输入条形码");
    }else if($.trim($("#price").val())==""){
        tishi_alert("请输入单价");
    }else if($("#num").val()==0 || $.trim($("#num").val())=="" || $("#num").val().match(reg1)==null){
        tishi_alert("请输入有效数字");
    }else{
      var barcode = $.trim($("#barcode").val());
      var mo_code = $.trim($("#code").val());
      var store_id = $("#hidden_store_id").val();
      $(obj).attr("disabled","disabled");
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
                      {
                         $(obj).attr("disabled",false);
                         return false;
                      }
               }else if(data=="0"){$("#ruku_tab_form").submit();}
               else{
                  $(obj).attr("disabled",false);
                  tishi_alert("未找到物料或者订单！");
                  return false;
               }
           },
           error:function(err){
              $(obj).attr("disabled",false);
              tishi_alert("出错了...");
              return false;
           }
       });
      
    }
}

function ruku(){
  $("#ruku_tab").find('input[type="text"]').val("");
  $("#ruku_tab").find('select').get(0).selectedIndex = 0;
  $("#ruku_tab .mat-out-list").html("");
  $("#ruku_tab .search_result_mat").html("");
  popup('#ruku_tab');
  return false;
}

function chuku(){
    $("#selected_materials").html("");
    $("#search_result").hide();
    $("#out_order_form").find("#name").attr("value","");
    var objs = $("#chuku_tab").find("select");
    for(var x=0;x<objs.length;x++){
      $(objs[x]).get(0).selectedIndex = 0;
    }
    $("#selected_items").attr("value","");
    popup('#chuku_tab');
    return false;
}

function dinghuo(s_id){
    $("#dinghuo_selected_materials").html("");
    $("#dinghuo_search_result").hide();
    $("#total_count").text("0");
    var objs = $("#dinghuo_tab").find("#material_types");
    for(var x=0;x<objs.length;x++){
        $(objs[x]).get(0).selectedIndex = 0;
    }
    $("#selected_items_dinghuo").attr("value","");
    popup("#dinghuo_tab");
    if(s_id==0)
     {
         $("#from").get(0).selectedIndex = 0;
         $("#add_material").hide();
         $("#activity_code").show();
     }
     else{
         $("#from").find("option[value="+s_id+"]").attr("selected", "selected");
         $("#add_material").show();
         $("#activity_code").hide();
     }
    
    $("#order_selected_materials").html("");
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

function save_order_remark(mo_id, store_id, obj){
    var content = $("#order_remark").val();
    if(mo_id!=null && content.length>0){
        $(obj).attr("disabled", "disabled");
        $.ajax({
            url:"/stores/"+store_id+"/materials/"+mo_id+"/order_remark",
            dataType:"json",
            type:"POST",
            data:"remark="+content,
            success: function(data){
                if(data == "1"){
                    hide_mask("#order_remark_div");
                    tishi_alert("操作成功");
                }
            },
            error:function(err){
              tishi_alert("出错了");
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

function cancel_order(order_id,type,store_id,mo_type){
  if(confirm("确认要取消订单吗？")){
      $.ajax({
          url:"/stores/"+store_id+"/materials/cancel_order",
          dataType:"json",
          type:"GET",
          data:"order_id="+order_id+"&type="+type,
          success:function(data,status){
              tishi_alert(data["content"]);
              if(mo_type==1){
                  $("#page_supplier_orders").find("#" + order_id).find("td:nth-child(8)").text("已取消")
              }else{
              $("#page_head_orders").find("#" + order_id).find("td:nth-child(8)").text("已取消")}
              
              hide_mask("#mat_order_detail_tab")
          },
          error:function(){
//              alert("error");
          }
      });
  }
}

function pay_order(mo_id,store_id){
    $.ajax({
            url: "/stores/"+store_id+"/materials/material_order" + "_pay",
            data:{mo_id:mo_id},
            dataType:"script",
            type:"GET",
            success:function(data){
              $('#mat_order_detail_tab').hide();
              $('#final_fukuan_tab #if_refresh').val("0")
            }
        })
       
}

function toggle_notice(obj){
    if($(obj).text()=="点击查看"){
       $(obj).text(" 隐藏");
    }else{$(obj).text("点击查看")}
    $(obj).next().toggle();
}
function toggle_low_materials(obj){
    if($(obj).text()=="点击查看"){
       $(obj).text(" 隐藏");
    }else{$(obj).text("点击查看")};
     $(obj).next().toggle();
}
function close_notice(obj){
    $(obj).parent().hide();
    $(obj).parent().next().hide();

   /* $.ajax({
        url:"/stores/"+store_id+"/materials/update_notices",
        dataType:"json",
        type:"GET",
        data:"ids="+ids,
        success:function(){
            window.location.reload();
        }
    });*/
}
  function setMaterialLow(){            //设置库存预警
    popup("#setMaterialLow");
    $("#material_low_value").focus();
  }
  function set_validate(){   //设置库存预警验证
    var num_flag = (new RegExp(/^\d+$/)).test($.trim($("#material_low_value").val()));
    if(num_flag == false ){
         tishi_alert("请输入正确的正整数!");
         return false;
    }else{
        $("#set_material_low_commit_button").click(function(){
            return false;
        })
    }
  }
  function set_material_low_count_validate(store_id,material_id){ //设置单个物料的库存预警
      //var a = $("#kucunliebiao .pageTurn").find("em").text();
      var num_flag = (new RegExp(/^\d+$/)).test($.trim($("#material_low_count").val()));
      var low_count = $("#material_low_count").val();
      if(num_flag){
         $("#remark_div").hide();
         $(".mask").hide();
         $.ajax({
             url: "/stores/"+store_id+"/materials/set_material_low_count_commit",
             dataType: "script",
             type: "get",         
             data: {low_count : low_count, mat_id : material_id}
         })
      }else{
         tishi_alert("请输入合法的数量!");
      }
  }

  function set_ignore(m_id, store_id,obj){   //忽略库存预警
      var obj_td = $(obj).parent();
      $.ajax({
          url: "/stores/"+store_id+"/materials/set_ignore",
          dataType: "json",
          type: "get",
          data: {
              m_id : m_id, store_id : store_id
          },
          success: function(data){
              if(data.status==0){
                  tishi_alert("操作失败!");
              }else if(data.status==1){
                tishi_alert("操作成功!");
                $(obj).parent().parent().find("td:first").removeAttr("class");
                $(obj).parent().parent().find("td:nth-child(4)").text("存货");
                obj_td.append("<a href='JavaScript:void(0)' onclick='cancel_ignore("+m_id+","+store_id+","+"this); return false;'>取消忽略</a>");
                $(obj).remove();
                if(data.material_storage <= data.material_low){         //如果设置忽略,且该物料小于库存预警，则要在缺货信息提示里把相应的物料删除掉
                    var l = $("#low_materials_tbody").find("#material"+m_id+"tr").length;  //判断该物料是否已经在缺货信息提示里
                    var low_materials_count = parseInt($("#low_materials_span").text());
                    if(l>0){          
                    $("#low_materials_span").text(low_materials_count-1);
                    $("#material"+m_id+"tr").remove();
                    $("#low_materials_tbody").find("tr").removeAttr("class");       //重新加上样式
                    $("#low_materials_tbody").find("tr:odd").attr("class", "tbg");
                    }
                    if((low_materials_count-1)==0){
                        $("#low_materials_span").parent().remove();
                    }
                }
              }
          }
      })
  }
  function cancel_ignore(m_id,store_id,obj){   //取消忽略库存预警
      var obj_td = $(obj).parent();
      $.ajax({
           url: "/stores/"+store_id+"/materials/cancel_ignore",
           dataType: "json",
           type: "get",
           data: {
               m_id : m_id, store_id : store_id
           },
           success: function(data){
                if(data.status==0){
                  tishi_alert("操作失败!");
                }else if(data.status==1){
                   tishi_alert("操作成功!");
                   if(data.material_storage <= data.material_low){
                      var message_span = $("span[id='low_materials_span']").length;            //判断是否有缺货提示
                      if(message_span<=0){              //如果没有缺货提示信息，则要加上缺货提示信息
                          $("#material_data_box").before("<div class='message'>有<span class='red' id='low_materials_span'>1</span>个物料库存量过低\n\
                                                            <a href='JavaScript:void(0)' onclick='toggle_low_materials(this)'>点击查看</a>\n\
                                                            <div style='display:none;'><table width='100%' border='0' cellspacing='0' cellpadding='0' class='data_tab_table'>\n\
                                                            <thead><tr class='hbg'><td>条形码</td><td>物料名称</td><td>物料类别</td><td>库存状态</td>\n\
                                                            <td>库存量(个)</td><td>成本价</td></tr></thead><tbody id='low_materials_tbody'><tr id='material"+m_id+"tr'>\n\
                                                            <td width='15%'>"+data.material_code+"</td><td>"+data.material_name+"</td><td>"+data.material_type+"</td><td>\n\
                                                            缺货</td><td id='materialstorage"+m_id+"td'>"+data.material_storage+"</td><td>"+
                                                            data.material_price+"</td></tr></tbody></table></div></div>")
                      }else{                //如果已有缺货提示，则只要加上一行记录
                       var low_materials_count = parseInt($("#low_materials_span").text()); 
                      $("#low_materials_span").text(low_materials_count+1);
                      var class_name = ($("#low_materials_tbody").find("tr:last").attr("class")=="tbg" ? "" : "tbg");
                      $("#low_materials_tbody").append("<tr id='material"+m_id+"tr' class="+class_name+"><td width='15%'>"+data.material_code+"</td><td>"+
                                                        data.material_name+"</td><td>"+data.material_type+"</td><td>缺货</td><td id='materialstorage"+m_id+"td'>"+
                                                        data.material_storage+"</td><td>"+data.material_price+"</td></tr>");
                      }
                      $(obj).parent().parent().find("td:first").removeAttr("class");
                      $(obj).parent().parent().find("td:first").attr("class", "data_table_error")
                      $(obj).parent().parent().find("td:nth-child(4)").text("缺货");
                   };
                   obj_td.append("<a href='JavaScript:void(0)' onclick='set_ignore("+m_id+","+store_id+","+"this);return false;'>忽略</a>");
                   $(obj).remove();
                }
           }
      })
  }
  function search_materials(tab_name, store_id, obj, mat_in_flag){
      var mat_code = $.trim($(obj).parents(".search").find("#search_material_code").val());
      var mat_name = $.trim($(obj).parents(".search").find("#search_material_name").val());
      var mat_type = $.trim($(obj).parents(".search").find("#search_material_type").val());
      var mo_code = $.trim($(obj).parents(".search").find("#material_order_code").val());
      $.ajax({
          url: "/stores/"+store_id+"/materials/search_materials",
          dataType: "script",
          type: "get",
          data: {
              tab_name : tab_name,
              mat_code : mat_code,
              mat_name : mat_name,
              mat_type : mat_type,
              store_id : store_id,
              mat_in_flag : mat_in_flag,
              mo_code : mo_code
          }
      })
  }

    function MaterialsLoss(){            //添加库存报损
        $("#mat_loss_search_result").empty();
        $("#MaterialsLoss #selected_materials").empty();
        popup("#MaterialsLoss");
    }

    function checkMaterialsLoss(store_id){
        var reg2 = /^\d+\.{0,1}\d*$/;
        var pattern = new RegExp("[=,-]")
        var f = true;
        if($.trim($("#material_loss_name").val())==""){
            tishi_alert("请输入物料名称");
            f = false;
        }else if($("#material_loss_name").val().match(pattern)!=null){
            tishi_alert("物料名称不能包含非法字符");
            f = false;
        }
        else if($.trim($("#material_loss_code").val())==""){
            tishi_alert("请输入条形码");
            f = false;
        }
        else if($("#material_loss_types").val()==""){
            tishi_alert("请选择类型");
            f = false;
        }
        else if($("#material_loss_price").val().match(reg2)==null){
            tishi_alert("请输入合法单价");
            f = false;
        }
        else if($("#material_loss_sale_price").val().match(reg2)==null){
            tishi_alert("请输入合法零售价");
            f = false;
        }
        else if($("#material_loss_num").val().match(reg1)==null){
            tishi_alert("请输入合法报损数量");
            f = false;
        }
        else if($("#material_loss_specifications").val()==""){
            tishi_alert("请输入物料规格");
            f = false;
        }
        else if($("#material_loss_staff_id").val()==""){
            tishi_alert("请选择报损人");
            f = false;
        }
        else{
            var name = $("#material_loss_name").val();
            var code = $("#material_loss_code").val();
            var types = $("#material_loss_types").val();
            var price = $("#material_loss_price").val();
            var sale_price = $("#material_loss_sale_price").val();
            var num = $("#material_loss_num").val();
            var specifications = $("#material_loss_specifications").val();
            var select_staff_id = $("#material_loss_staff_id").val();
            var id =  $("#material_loss_id").val();
            $.ajax({
                url: "/stores/" +store_id+ "/materials_losses/add",
                dataType: "text",
                type: "post",
                data: {
                    name : name,
                    code : code,
                    types : types,
                    price : price,
                    sale_price : sale_price,
                    loss_num : num,
                    specifications : specifications,
                    report_person : select_staff_id,
                    id : id

                },
                success:function(data,status){
                    if(id == "")
                        tishi_alert("报损成功!");
                    else
                        tishi_alert("修改成功!");
                    $("#MaterialsLoss").hide();
                    $(".mask").hide();
                    location.reload();
                },
                error:function(){
                    if(id == "")
                        tishi_alert("报损失败!");
                    else
                        tishi_alert("修改失败!");
                }
            });
        }
    }

    function deleteMaterails_loss(store_id,materials_loss_id)
    {
        if(confirm("确定删除吗？"))
            $.ajax({
                url: "/stores/" +store_id+ "/materials_losses/delete",
                dataType:"text",
                type:"get",
                data:{materials_loss_id : materials_loss_id},
                success:function(data,status){
                    tishi_alert("删除成功!");
                    location.reload();
                },
                error:function(){
                    tishi_alert("删除失败!");
                }
            });
    }

    function viewMaterails_loss(store_id,materials_loss_id)
    {
        $.ajax({
            url: "/stores/" +store_id+ "/materials_losses/view",
            dataType:"text",
            data:{materials_loss_id : materials_loss_id},
            success:function(data,status)
            {
                var materail_loss = $.parseJSON(data);
                $("#material_loss_name").val(materail_loss.name);
                $("#material_loss_code").val(materail_loss.code);
                $("#material_loss_types").val(materail_loss.types);
                $("#material_loss_price").val(materail_loss.price);
                $("#material_loss_sale_price").val(materail_loss.sale_price);
                $("#material_loss_num").val(materail_loss.loss_num);
                $("#material_loss_specifications").val(materail_loss.specifications);
                $("#material_loss_staff_id").val(materail_loss.staff_id);
                $("#material_loss_id").val(materail_loss.id);
                popup("#MaterialsLoss");
            }
        });
    }
  function fetchMatIn(obj){
    var saved_mat_mos = "";
    $("#ruku_tab .mat-out-list").find("tr").each(function(index){
        var mat_code = $(this).find(".mat_code").text();
        var mo_code = $(this).find(".mo_code").text();
        var num = $(this).find(".mat_item_num").text();
        // var mat_name = $(this).find(".mat_name").text();
        var each_item = "";
        each_item += mat_code + "_";
        each_item += mo_code + "_";
        each_item += num;
        saved_mat_mos += each_item + ",";
    })
    $("#ruku_tab #mat_in_hidden_value").val(saved_mat_mos);
    $("#ruku_tab #mat_in_create").val(0);
    if(saved_mat_mos != "")
    {
        $("#ruku_tab #mat_in_hidden_value").val(saved_mat_mos);
        $(obj).parents("#create_mat_in_form").submit();
    }
  }

  function checkPrintNum(){
      var f = true;
      $("#print_code_tab #selected_materials").find('input.print_code').each(function(){
         if($(this).val().match(reg1)==null){
             var code = $(this).attr('alt');
             alert("条形码为"+ code + "的物料数量不正确！");
             f = false;
         }
      })
      return f;
  }


  function checkMatLossNum(){
      var f = true;
      $("#MaterialsLoss #selected_materials").find('input.mat_loss_num').each(function(){
         if($(this).val().match(reg1)==null){
            var code = $(this).attr('code');
            alert("条形码为'"+ code + "'的物料数量不正确！");
            f = false;
         }
      })
      return f;
  }