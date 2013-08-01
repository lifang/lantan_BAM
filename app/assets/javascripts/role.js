/**
 * Created with JetBrains RubyMine.
 * User: alec
 * Date: 13-2-27
 * Time: 下午1:16
 * To change this template use File | Settings | File Templates.
 */

function add_role(store_id){
    popup("#add_role");
    $("#role_input").attr("value","");

}

function new_role(store_id){
    if($.trim($("#role_input").val()).length==0){
        tishi_alert("请输入角色名称");
    }else{
        $.ajax({
            url:"/stores/"+store_id+"/roles/",
            type:"POST",
            dataType:"json",
            data:"name="+ $.trim($("#role_input").val())+"&store_id=" + store_id,
            success:function(data,status){
                if(data["status"]==0){
                    $("#add_role").hide();
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
                  {$("#a_role_"+role_id).html($.trim($(obj).val()));}
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
    $(".groupFunc_b input[type='checked']").each(function(idx,item){
        if($(item).attr("checked")){
            $(item).removeAttribute("checked");
        }
    });
    if(r_ids.length>0){
        for(var i=0;i<r_ids.split(",").length;i++){
            $("#check_role_"+r_ids.split(",")[i]).attr("checked",'true');
        }
    }
    $("#staff_id_h").attr("value",staff_id);
}

function search_staff(store_id){
    $.ajax({
        url:'/stores/'+store_id+'/roles/staff',
        dataType:"script",
        type:"GET",
        data:"name="+ $.trim($("#name").val()),
        success:function(){
        //           alert(2);
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
function checkValid(obj){
    var flag = true;
    if($(".station_form").find(".station_name input").val()=="")
        {
           tishi_alert("名称不能为空!")
            flag = false;
            return false;
        }
    else if($(".station_form #station_is_has_controller").attr("checked")=="checked")
       {
           $(".station_form .controller_input").find("input[type='text']").each(function(){
            var name = $(this).prev().text().split("：")[0]
            if($(this).val()==""){
                tishi_alert(name.split("*")[1]+"不能为空!")
                flag = false;
                return false;
            }
        })
       }
    else if($(".station_form .popup_body_result").find("input[type='checkbox']:checked").length==0){
        tishi_alert("服务不能为空!")
        flag = false;
    }
    if(flag)
    {
        $(obj).parents("form").submit();
    }
}
function handleController(){
    var input_div = $("#station_is_has_controller").parent().next();
    if($("#station_is_has_controller").attr("checked")=="checked")
    {
        $(".station_form .controller_input").find('label').prepend("<span class='red'>*</span>");
        input_div.find("input").attr("disabled", false);
    }
    else{
        input_div.find("input").attr("disabled","disabled");
        $(".station_form .controller_input").find('label span').remove();
    }
}