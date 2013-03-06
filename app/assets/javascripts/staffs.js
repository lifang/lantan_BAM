// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function remove_area(parent, close, cancel){
    $(close, cancel).bind('click',function(){
        $(".mask").hide();
        $(parent).html('');
    });
    return false;
}

$(document).ready(function(){

    //创建员工
    $("#new_staff").click(function(){
        popup("#new_staff_area");
        return false;
    });

    //创建违规
    $("#new_violation").click(function(){
        popup("#new_violation_area");
        return false;
    });

    //创建奖励
    $("#new_reward").click(function(){
        popup("#new_reward_area");
        return false;
    });

    //创建培训
    $("#new_train").click(function(){
        popup("#new_train_area");
        return false;
    });

    //创建员工信息验证
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

    //新建奖励信息验证
    $("#new_reward_btn").click(function(){
       if($("#new_reward_area input:checked").length == 0){
           alert("至少选择一个奖励人员");
           return false;
       }
       if($("#violation_reward_situation").val() == ""){
           alert("奖励原因不能为空!");
           return false;
       }
       if($("#violation_reward_mark").val() == ""){
           alert("补充说明不能为空!");
           return false;
       }
       $(this).parents('form').submit();
    });

    //取消按钮
    $(".cancel_btn").click(function(){
       $(".tab_popup").hide();
       $(".mask").hide();
       return false;
    });

    //编辑系统打分
    $("#staff_info .bz_btn").click(function(){
        $(this).prev().show();
        $(this).hide();
        $(this).parents('tr').find(".sys_score_text").hide();
        $(this).parents('tr').find(".data_input_s").show();
        return false;
    });

    //编辑提交系统打分
    $(".edit_btn").click(function(){
        var this_obj = $(this);
        var store_id = $("#store_id").val();
        var month_score_id = $(this).parents('tr').find(".data_input_s").attr("id");
        var sys_score = $(this).parents('tr').find(".data_input_s").val();
        $.ajax({
            type : 'get',
            url : "/stores/"+ store_id+"/month_scores/update_sys_score",
            data : {
                sys_score : sys_score,
                month_score_id : month_score_id
            },
            success: function(data){
               if(data == "success"){
                   this_obj.parents('tr').find(".data_input_s").hide();
                   this_obj.parents('tr').find(".sys_score_text").text(sys_score).show();
                   this_obj.hide();
                   this_obj.next().show();
               }
            }
        });
        return false;
    });

    //编辑系统打分在绩效记录页面
    $("#edit_sys_score").click(function(){
       $(this).hide();
       $(this).prev().show();
       $("#sys_score_text").hide();
       $("#sys_score_input").show();
       return false;
    });

    //提交编辑系统打分在绩效记录页面
    $("#edit_sys_score_submit").click(function(){
       var this_obj = $(this);
       var sys_score = $("#sys_score_input").val();
       var store_id = $("#store_id").val();
       var month_score_id = $(this).attr("name");
       $.ajax({
            type : 'get',
            url : "/stores/"+ store_id+"/month_scores/update_sys_score",
            data : {
                sys_score : sys_score,
                month_score_id : month_score_id
            },
            success: function(data){
               if(data == "success"){
                   this_obj.hide();
                   this_obj.next().show();
                   $("#sys_score_text").text(sys_score).show();
                   $("#sys_score_input").hide();
               }
            }
        });
        return false;
    });

    //编辑提成金额扣款金额
    $("#salary_info .bz_btn").click(function(){
       $(this).hide();
       $(this).prev().show();
       $(this).parents('tr').find(".reward_num_text").hide();
       $(this).parents('tr').find(".reward_num_input").show();
       $(this).parents('tr').find(".deduct_num_text").hide();
       $(this).parents('tr').find(".deduct_num_input").show();
       return false;
    });

    //提交编辑提成金额扣款金额
    $(".edit_reward_deduct_submit").click(function(){
       var this_obj = $(this);
       var store_id = $("#store_id").val();
       var reward_num = $(this).parents('tr').find(".reward_num_input").val();
       var deduct_num = $(this).parents('tr').find(".deduct_num_input").val();
       var salary_id = $(this).attr("id");
       $.ajax({
            type : 'put',
            url : "/stores/"+ store_id+"/salaries/" + salary_id,
            data : {
                reward_num : reward_num,
                deduct_num : deduct_num
            },
            success: function(data){
               if(data == "success"){
                   this_obj.hide();
                   this_obj.next().show();
                   this_obj.parents('tr').find(".reward_num_input").hide();
                   this_obj.parents('tr').find(".deduct_num_input").hide();
                   this_obj.parents('tr').find(".deduct_num_text").text(deduct_num).show();
                   this_obj.parents('tr').find(".reward_num_text").text(reward_num).show();
               }
            }
        });
       return false;
    });

    //员工详情
    $("#staff_detail").click(function(){
        var staff_id = $("#staff_id").val();
        var store_id = $("#store_id").val();
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

    //店长打分页面
    $("#manage_score_btn").click(function(){
       popup("#manage_score_area");
       return false;
    });

    //处理奖励
    $(".process_reward").click(function(){
       var store_id = $(this).attr("name");
       var id = $(this).attr("id");
       $.ajax({
            async:true,
            type : 'get',
            dataType : 'script',
            url : "/stores/"+ store_id+"/violation_rewards/"+ id +"/edit",
            data : {
                id : id,
                store_id : store_id
            }
        });
       return false;
    });

    //处理违规
    $(".process_violation").click(function(){
       var store_id = $(this).attr("name");
       var id = $(this).attr("id");
       $.ajax({
            async:true,
            type : 'get',
            dataType : 'script',
            url : "/stores/"+ store_id+"/violation_rewards/"+ id +"/edit",
            data : {
                id : id,
                store_id : store_id
            }
        });
       return false;
    });

    //ajax paginate
    $("#ajax_paginate .pageTurn a").live("click", function(){
       var params_string = $(this).attr("href").split("?")[1];
       var store_id = $("#store_id").val();
       var staff_id = $("#staff_id").val();
       var tab = $(this).parents('.pageTurn').parent().attr("id");
       $.ajax({
            async:true,
            type : 'get',
            dataType : 'script',
            url : "/stores/" + store_id + "/staffs/" + staff_id + "?" + params_string,
            data : {tab:tab}
        });
       return false;
    });

    //日期选择
    $("#train_start_at").datepicker({inline:true});
    $("#train_end_at").datepicker({inline:true});
    $("#start_at").datepicker({inline:true});
    $("#end_at").datepicker({inline:true});

    //查询工作记录
    $("#search_work_record").click(function(){
       var start_at = $(this).parents('.search').find("#start_at").val();
       var end_at = $(this).parents('.search').find("#end_at").val();
       var staff_id = $(this).parents('.search').find("#staff_id").val();
       var store_id = $(this).parents('.search').find("#store_id").val();
       var tab = "work_record_tab";
       var cal_style = $(".cal_style:checked").val();
       $.ajax({
            async:true,
            type : 'get',
            dataType : 'script',
            url : "/stores/"+ store_id + "/staffs/" + staff_id,
            data : {
                start_at : start_at,
                end_at : end_at,
                tab : tab,
                cal_style : cal_style
            }
        });
       return false;
    });

    //删除工资记录
    $(".delete_salary").live("click", function(){
       if(confirm("确认删除？")){
           var id = $(this).attr("id");
           var store_id = $(this).attr("name");
           $.ajax({
                async:true,
                type : 'DELETE',
                dataType : 'script',
                url : "/stores/"+ store_id +"/salaries/"+ id,
                data : {}
            });
       }
       return false;
    });

    //选择 月份 统计员工工资
    $("#statistics_date_select").change(function(){
       $(this).parents('form').submit();
       return false;
    });

});
