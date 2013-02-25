// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function center_popup(t){
    var doc_height = $(document).height();
    var doc_width = $(document).width();
    //var win_height = $(window).height();
    //var win_width = $(window).width();

    var layer_height = $(t).height();
    var layer_width = $(t).width();

    //tab

    $(".mask").css({
        display:'block',
        height:doc_height
    });
    //$(t).css('top',(doc_height-layer_height)/2);
    $(t).css('top',"50px");
    $(t).css('left',(doc_width-layer_width)/2);
    $(t).css('display','block');
    return false;
}

function remove_area(parent, close, cancel){
    $(close, cancel).bind('click',function(){
        $(".mask").hide();
        $(parent).html('');
    });
    return false;
}

$(document).ready(function(){

    $("#new_staff").click(function(){
        popup("#new_staff_area");
        return false;
    });

    $("#new_violation").click(function(){
        popup("#new_violation_area");
        return false;
    });

    $("#new_reward").click(function(){
        popup("#new_reward_area");
        return false;
    });

    $("#new_train").click(function(){
        popup("#new_train_area");
        return false;
    });

    $("#new_staff_btn").click(function(){
       if($(this).parents('form').find("#staff_name").val() == ""){
           alert("名称不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_type_of_w").val() == ""){
           alert("岗位不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_level").val() == ""){
           alert("等级职称不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_education").val() == ""){
           alert("教育程度不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_phone").val() == ""){
           alert("联系方式不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_id_card").val() == ""){
           alert("身份证不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_address").val() == ""){
           alert("地址不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_base_salary").val() == ""){
           alert("薪资标准不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_photo").val() == ""){
           alert("照片不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_deduct_at").val() == ""){
           alert("提成起始额不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_deduct_end").val() == ""){
           alert("结束额度不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_deduct_percent").val() == ""){
           alert("提成率不能为空!");
           return false;
       }
       $(this).parents('form').submit();
    });

    $(".cancel_btn").click(function(){
       $(".tab_popup").hide();
       $(".mask").hide();
       return false;
    });

    $(".bz_btn").click(function(){
        var staff_id = $(this).attr("id");
        var store_id = $(this).attr("name");
        $.ajax({
            async:true,
            type : 'get',
            dataType : 'script',
            url : "/stores/"+ store_id+"/staffs/"+ staff_id +"/edit",
            data : {
                staff_id : staff_id,
                store_id : store_id
            }
        });
        return false;
    });

    $("#manage_score_btn").click(function(){
       popup("#manage_score_area");
       return false;
    });

});
