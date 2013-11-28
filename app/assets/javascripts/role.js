/**
 * Created with JetBrains RubyMine.
 * User: alec
 * Date: 13-2-27
 * Time: 下午1:16
 * To change this template use File | Settings | File Templates.
 */
 var reg1 =  /^\d+$/;
function add_role(store_id){
    popup("#add_role");
    $("#role_input").attr("value","");

}

function new_role(store_id){
    if($.trim($("#role_input").val()).length==0){
        tishi_alert("请输入角色名称");
    }else if($.trim($("#role_input").val()).length > 8){
        tishi_alert("角色名称不能超过8个汉字");
    }else{
        $.ajax({
            url:"/stores/"+store_id+"/roles/",
            type:"POST",
            dataType:"json",
            data:"name="+ $.trim($("#role_input").val())+"&store_id=" + store_id,
            success:function(data,status){
                if(data["status"]==0){
                    $("#add_role").hide();
                    tishi_alert("角色添加成功");
                    window.location.reload();
                }else if(data["status"]==1){
                    tishi_alert("你输入的角色已经存在");
                }
            },
            error:function(data){
                tishi_alert("添加失败");
            }
        });
    }
}

function edit_role(role_id){
    $("#a_role_"+role_id).hide();
    $("#input_role_"+role_id).show().focus();

}

function blur_role(obj,store_id){
    var role_id = $(obj).attr("id").split("_")[2];
    if($.trim($(obj).val()).length==0){
        tishi_alert("请输入角色名称");
    }else if($.trim($(obj).val()).length > 8){
        tishi_alert("角色名称不能超过8个汉字");
    }else if($.trim($(obj).val())==$("#a_role_"+role_id).text()){
        $("#a_role_"+role_id).show();
        $(obj).hide();
    }else{
        $.ajax({
            url:"/stores/"+store_id+"/roles/"+role_id,
            type:"PUT",
            dataType:"json",
            data:"name="+ $.trim($(obj).val())+"&store_id=" + store_id,
            success:function(data,status){
                if(data['status']=="0")
                  {   
                      tishi_alert("角色编辑成功")
                      $("#a_role_"+role_id).html($.trim($(obj).val()));}
                else{
                   tishi_alert("当前角色不存在")
                  }
            },
            error:function(data){
                tishi_alert(data);
            }
        });
        $("#a_role_"+role_id).show();
        $(obj).hide();
    }
}

function set_role(obj,role_id,store_id){
    $(".people_group li").css({
        backgroundColor:"#ffffff"
    });
    $(obj).parent().parent().css({
        backgroundColor:"#ebebeb"
    });
    $.ajax({
        url:this.href,
        dataType:"script",
        type:"GET",
        data:"role_id="+role_id+"&store_id="+store_id,
        success:function(){
            $("#model_div").show();
            $("#role_id").attr("value",role_id);
        }
    });
}

function set_staff_role(staff_id,r_ids){
    popup("#set_role");
    $(".groupFunc_b input[type='checkbox']").each(function(idx,item){
        if($(item).attr("checked")=="checked"){
            $(item).attr("checked", false)
        }
    });
    if(r_ids.length>0){
        for(var i=0;i<r_ids.split(",").length;i++){
            $("#check_role_"+r_ids.split(",")[i]).attr("checked",'checked');
        }
    }
    $("#staff_id_h").attr("value",staff_id);
}

function search_staff(store_id){
    $.ajax({
        url:"/stores/"+store_id+"/roles/staff",
        dataType:"script",
        type:"GET",
        data: {name : $.trim($("#name").val())},
        success:function(){
                 
        },
        error:function(){
            tishi_alert("error");
        }
    });
}

function del_role(role_id,store_id){
    if(confirm("确定要删除该角色吗")){
        $.ajax({
            url:"/stores/"+store_id+"/roles/"+role_id,
            dataType:"json",
            type:"delete",
            success:function(){
                tishi_alert("角色删除成功")
                window.location.reload();
            }
        });
    }
}

function reset_role(store_id){
    var len = $(".groupFunc_b input:checked").length;
    if(len==0){
        tishi_alert("请选择角色");
    }else{
        var roles = "";
        $(".groupFunc_b input:checked").each(function(idx,item){
            roles += $(item).val()+",";
        });
        $.ajax({
            url:"/stores/"+store_id+"/roles/reset_role",
            dataType:"json",
            type:"POST",
            data:"staff_id="+$("#staff_id_h").val()+"&roles="+roles,
            success:function(){
                tishi_alert("设定成功")
                window.location.replace(window.location.href)
                
            },
            error:function(){

            }
        });
    }
}

function cancel_role_panel(){
    $('#model_div').hide();
    $(".people_group li").css({
        backgroundColor:"#ffffff"
    });
}

function selectAll(obj){
    if($(obj).attr("checked")=="checked"){
        $(obj).parent().next().find("input[type='checkbox']").attr("checked", "checked")
    }else{
        $(obj).parent().next().find("input[type='checkbox']").attr("checked", false)
    }
}
//这边是工位的开始
function new_station_valid(obj){ //新建工控机验证
    var product = $("input[name='product_ids[]']:checked").length;
    var name = $("#station_name").val();
    var code = $("#station_code").val();
    var has_controller = $("#station_has_controller").attr("checked")=="checked";
    var station_code = $.trim($("#station_collector_code").val());
    if(name==""){
        tishi_alert("工控机名称不能为空!");
    }else if(code==""){
        tishi_alert("工控机编号不能为空!");
    }else if(has_controller && station_code==""){
        tishi_alert("采集器编号不能为空!")
    }else if(product==0){
        tishi_alert("至少选择一个服务项目!");
    }else{
        $(obj).parents("form").submit();
        //$(obj).attr("disabled", "disabled");
    }
}

function edit_station_valid(obj){ //编辑工控机验证
    var product = $("input[name='edit_product_ids[]']:checked").length;
    var name = $("#edit_station_name").val();
    var code = $("#edit_station_code").val();
    var has_controller = $("#edit_station_has_controller").attr("checked")=="checked";
    var station_code = $.trim($("#edit_station_collector_code").val());
    if(name==""){
        tishi_alert("工控机名称不能为空!");
    }else if(code==""){
        tishi_alert("工控机编号不能为空!");
    }else if(has_controller && station_code==""){
        tishi_alert("采集器编号不能为空!")
    }else if(product==0){
        tishi_alert("至少选择一个服务项目!");
    }else{
        $(obj).parents("form").submit();
        //$(obj).attr("disabled", "disabled");
    }
}

function handleController(obj){            //修改是否有工控机修改采集器编号可否输入
   if($(obj).attr("checked")=="checked"){
       $(".controller_input label").prepend("<span class='red'>*</span>");
       $(".controller_input input").removeAttr("disabled");
   }else{
       $(".controller_input span").remove();
       $(".controller_input input").attr("disabled", "disabled");
   }
}