// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function remove_area(parent, close, cancel){
    $(close, cancel).bind('click',function(){
        $(".mask").hide();
        $(parent).html('');
    });
    return false;
}

function assess_result(sys_score, manage_score){
    var total = parseInt(sys_score) + parseInt(manage_score);
    if(total >= 90){
        result = "优秀";
    }
    if(total >= 80 && total < 90){
        result = "良好";
    }
    if(total >= 70 && total < 80){
        result = "一般";
    }
    if(total >= 60 && total < 70){
        result = "及格";
    }
    if(total < 60){
        result = "不及格";
    }
    return result;
}

$(document).ready(function(){
   
    $("#work_record_table").tablesorter({
        headers:
        {

            1: {sorter: false},
            2: {sorter: false},
            3: {sorter: false},
            4: {sorter: false},
            5: {sorter: false},
            6: {sorter: false},
            7: {sorter: false},
            8: {sorter: false},
            9: {sorter: false}

        }
    });
    $("#work_record_table").bind("sortEnd",function() {
        $("#work_record_table").find('tr').each(function(i){
            if(i%2==0){
                $(this).removeClass('tbg');
            }else{
                $(this).addClass('tbg');
            }
        })
    });     
    $("#month_score_table").tablesorter({
        headers:
        {

            1: {sorter: false},
            2: {sorter: false},
            3: {sorter: false}

        }
    });
    $("#month_score_table").bind("sortEnd",function() {
        $("#month_score_table").find('tr').each(function(i){
            if(i%2==0){
                $(this).removeClass('tbg');
            }else{
                $(this).addClass('tbg');
            }
        })
    });
    $("#reward_table").tablesorter({
        headers:
        {

            1: {sorter: false},
            2: {sorter: false},
            3: {sorter: false},
            4: {sorter: false}

        }
    });
    $("#reward_table").bind("sortEnd",function() {
        $("#reward_table").find('tr').each(function(i){
            if(i%2==0){
                $(this).removeClass('tbg');
            }else{
                $(this).addClass('tbg');
            }
        })
    });
    $("#salary_table").tablesorter({
        headers:
        {
            1: {sorter: false},
            2: {sorter: false},
            3: {sorter: false},
            4: {sorter: false}
        }
    });
    $("#salary_table").bind("sortEnd",function() {
        $("#salary_table").find('tr').each(function(i){
            if(i%2==0){
                $(this).removeClass('tbg');
            }else{
                $(this).addClass('tbg');
            }
        })
    });
    $("#train_table").tablesorter({
        headers:
        {

            1: {sorter: false},
            2: {sorter: false},
            3: {sorter: false},
            4: {sorter: false},
            5: {sorter: false}

        }
    });
    $("#train_table").bind("sortEnd",function() {
        $("#train_table").find('tr').each(function(i){
            if(i%2==0){
                $(this).removeClass('tbg');
            }else{
                $(this).addClass('tbg');
            }
        })
    });
    $("#violation_table").tablesorter({
        headers:
        {

            1: {sorter: false},
            2: {sorter: false},
            3: {sorter: false},
            4: {sorter: false}

        }
    });
    $("#violation_table").bind("sortEnd",function() {
        $("#violation_table").find('tr').each(function(i){
            if(i%2==0){
                $(this).removeClass('tbg');
            }else{
                $(this).addClass('tbg');
            }
        })
    });
    $("#current_month_salary_table").tablesorter({
        headers:
        {

            1: {sorter: false},
            2: {sorter: false},
            5: {sorter: false},
            6: {sorter: false}

        }
    });
    $("#current_month_salary_table").bind("sortEnd",function() {
        $("#current_month_salary_table").find('tr').each(function(i){
            if(i%2==0){
                $(this).removeClass('tbg');
            }else{
                $(this).addClass('tbg');
            }
        })
    });
//    $(".sort_u_s, .sort_d_s").click(function(){
//        if($(this).attr("class") == "sort_u_s"){
//            $(this).attr("class", "sort_d_s");
//        }else{
//            $(this).attr("class", "sort_u_s");
//        }
//    });

    //提示信息居中
    //popup(".tab_alert");

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

    $("#staff_working_stats").live("change", function(){        //选择在职状态时
        if($(this).val() == 1){
            $(this).parent().parent().find($("#staff_probation_days")).attr("disabled", "disabled");
            //$(this).parent().parent().find($("#staff_probation_days")).val("");
            $(this).parent().parent().find($("#staff_probation_salary")).attr("disabled", "disabled");
            //$(this).parent().parent().find($("#staff_probation_salary")).val("");
        }else{
            $(this).parent().parent().find($("#staff_probation_days")).removeAttr("disabled");
            $(this).parent().parent().find($("#staff_probation_salary")).removeAttr("disabled");
        }
    });
    $("#staff_is_deduct").live("click", function(){             //是否参加提成
        if($(this).attr("checked")=="checked"){
            $(this).parent().parent().find($("#staff_deduct_at")).removeAttr("disabled");
            $(this).parent().parent().find($("#staff_deduct_end")).removeAttr("disabled");
            $(this).parent().parent().find($("#staff_deduct_percent")).removeAttr("disabled");
        }else{
            $(this).parent().parent().find($("#staff_deduct_at")).attr("disabled", "disabled");
            //$(this).parent().parent().find($("#staff_deduct_at")).val("");
            $(this).parent().parent().find($("#staff_deduct_end")).attr("disabled", "disabled");
            //$(this).parent().parent().find($("#staff_deduct_end")).val("");
            $(this).parent().parent().find($("#staff_deduct_percent")).attr("disabled", "disabled");
            //$(this).parent().parent().find($("#staff_deduct_percent")).val("");
        }
    })
    //创建员工信息验证, 编辑员工信息验证
    $("#new_staff_btn, #edit_staff_btn").live("click", function(){
       if($.trim($(this).parents('form').find("#staff_name").val()) == ''){
           tishi_alert("名称不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_working_stats").val() == 0 && $(this).parents('form').find("#staff_probation_days").val()==''){
           tishi_alert("请输入实习时间!");
           return false;
       }
       if($(this).parents('form').find("#staff_working_stats").val() == 0 && isNaN($(this).parents('form').find("#staff_probation_days").val())){
           tishi_alert("请输入有效的实习期!");
           return false;
       }
       if($.trim($(this).parents('form').find("#staff_phone").val()) == ''){
           tishi_alert("联系方式不能为空!");
           return false;
       }
       if($.trim($(this).parents('form').find("#staff_id_card").val()) == ''){
           tishi_alert("身份证不能为空!");
           return false;
       }
       if($.trim($(this).parents('form').find("#staff_address").val()) == ''){
           tishi_alert("地址不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_working_stats").val() == 0 && $.trim($(this).parents('form').find("#staff_probation_salary").val()) == ''){
           tishi_alert("实习期薪资标准不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_working_stats").val() == 0 && isNaN($(this).parents('form').find("#staff_probation_salary").val())){
           tishi_alert("实习薪资必须为数字!");
           return false;
       }
       if($.trim($(this).parents('form').find("#staff_base_salary").val()) == ''){
           tishi_alert("正式薪资标准不能为空!");
           return false;
       }
       if(isNaN($(this).parents('form').find("#staff_base_salary").val())){
           tishi_alert("正式薪资标准必须为数字!");
           return false;
       }
       if($(this).parents('form').find("#staff_is_deduct").attr("checked")=="checked" && $.trim($(this).parents('form').find("#staff_deduct_at").val()) == ''){
           tishi_alert("提成起始额不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_is_deduct").attr("checked")=="checked" && isNaN($(this).parents('form').find("#staff_deduct_at").val())){
           tishi_alert("提成起始额必须为数字!");
           return false;
       }
       if($(this).parents('form').find("#staff_is_deduct").attr("checked")=="checked" && $.trim($(this).parents('form').find("#staff_deduct_end").val()) == ''){
           tishi_alert("结束额度不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_is_deduct").attr("checked")=="checked" && isNaN($(this).parents('form').find("#staff_deduct_end").val())){
           tishi_alert("结束额度必须为数字!");
           return false;
       }
       if($(this).parents('form').find("#staff_is_deduct").attr("checked")=="checked" && (parseFloat($(this).parents('form').find("#staff_deduct_at").val()) > parseFloat($(this).parents('form').find("#staff_deduct_end").val()))){
           tishi_alert("起始额必须不能大于结束额度!");
           return false;
       }
       if($(this).parents('form').find("#staff_is_deduct").attr("checked")=="checked" && $.trim($(this).parents('form').find("#staff_deduct_percent").val()) == ''){
           tishi_alert("提成率不能为空!");
           return false;
       }
       if($(this).parents('form').find("#staff_is_deduct").attr("checked")=="checked" && isNaN($(this).parents('form').find("#staff_deduct_percent").val())){
           tishi_alert("提成率必须为数字!");
           return false;
       }
//       if($(this).attr("id") == "new_staff_btn"){
//           if($(this).parents('form').find("#staff_photo").val() == ''){
//               tishi_alert("照片不能为空!");
//               return false;
//           }else{
//               var input_s = document.getElementById('staff_photo');
//               var file_size = input_s.files[0].size;
//               if(file_size > 500*1024){
//                  tishi_alert("图片大小不能超过500k！");
//                  return false;
//               }
//               var img_val = $(this).parents('form').find("#staff_photo").val();
//               var pattern_str = new RegExp("[`~!@#$^&*()=|{}':;',\\[\\].<>/?~！@#￥……&*（）——|{}【】‘；：”“'。，、？]");
//               var img_name_val = img_val.substring(img_val.lastIndexOf("\\")).toLowerCase();
//               var g_name_val = img_name_val.substring(1,img_name_val.length);
//               if(pattern_str.test(g_name_val.split(".")[0])){
//                  tishi_alert(g_name_val+"不能包含特殊字符!");
//                  return false;
//               }
//
//               var img_suff = img_val.substring(img_val.lastIndexOf('.') + 1).toLowerCase();
//               if(img_suff == "gif" || img_suff == "jpg" || img_suff == "png" || img_suff == "bmp"){
//               }else{
//                  tishi_alert("图片格式不对!");
//                  return false;
//               }
//           }
//       }
       //if($(this).attr("id") == "edit_staff_btn"){
           if($(this).parents('form').find("#staff_photo").val() != ''){
               var input_e = document.getElementById('staff_photo');
               var file_size_e = input_e.files[0].size;
               if(file_size_e > 500*1024){
                  tishi_alert("图片大小不能超过500k！");
                  return false;
               }
               var edit_img_val = $(this).parents('form').find("#staff_photo").val();
               var pattern = new RegExp("[`~!@#$^&*()=|{}':;',\\[\\].<>/?~！@#￥……&*（）——|{}【】‘；：”“'。，、？]")
               var img_name = edit_img_val.substring(edit_img_val.lastIndexOf("\\")).toLowerCase();
               var g_name = img_name.substring(1,img_name.length);
               if(pattern.test(g_name.split(".")[0])){
                  tishi_alert(g_name+"不能包含特殊字符!");
                  return false;
               }
               var edit_img_suff = edit_img_val.substring(edit_img_val.lastIndexOf('.') + 1).toLowerCase();
               if(edit_img_suff == "gif" || edit_img_suff == "jpg" || edit_img_suff == "png" || edit_img_suff == "bmp"){
               }else{
                  tishi_alert("图片格式不对!");
                  return false;
               }
           }
       //}
       $(this).parents('form').submit();
       $(this).attr("disabled", "disabled");
    });

    //新建奖励信息验证
    $("#new_reward_btn").click(function(){
        if($("#new_reward_area input:checked").length == 0){
            tishi_alert("至少选择一个奖励人员!");
            return false;
        }
        if($.trim($("#new_reward_area #violation_reward_situation").val()) == ''){
            tishi_alert("奖励原因不能为空!");
            return false;
        }
        if($.trim($("#new_reward_area #violation_reward_mark").val()) == ''){
            tishi_alert("补充说明不能为空!");
            return false;
        }
        $(this).parents('form').submit();
        $(this).attr("disabled", "disabled");
    });

    //新建违规信息验证
    $("#new_violation_btn").click(function(){
        if($("#new_violation_area input:checked").length == 0){
            tishi_alert("至少选择一个违规人员!");
            return false;
        }
        if($.trim($("#new_violation_area #violation_reward_situation").val()) == ''){
            tishi_alert("违规原因不能为空!");
            return false;
        }
        if($.trim($("#new_violation_area #violation_reward_mark").val()) == ''){
            tishi_alert("补充说明不能为空!");
            return false;
        }
        $(this).parents('form').submit();
        $(this).attr("disabled", "disabled");
    });

    //新建培训信息验证
    $("#new_train_btn").click(function(){
        if($("#new_train_area #train_start_at").val() == ''){
            tishi_alert("培训开始时间不能为空!");
            return false;
        }
        if($("#new_train_area #train_end_at").val() == ''){
            tishi_alert("培训结束时间不能为空!");
            return false;
        }
        if(new Date($("#new_train_area #train_start_at").val()) > new Date($("#new_train_area #train_end_at").val())){
            tishi_alert("培训开始时间必须在培训结束时间之后!");
            return false;
        }
        if($("#new_train_area input:checked").length == 0){
            tishi_alert("至少选择一个培训人员!");
            return false;
        }
        if($.trim($("#new_train_area #train_content").val()) == ''){
            tishi_alert("培训原因不能为空!");
            return false;
        }
        $(this).parents('form').submit();
        $(this).attr("disabled", "disabled");
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
        if(isNaN(sys_score)){
            tishi_alert("系统打分必须为数字!");
            return false;
        }
        var manage_score = $(this).parents('tr').find(".manage_score_data").text();
        if(manage_score != ""){
            var total = parseInt(sys_score) + parseInt(manage_score);
            if(total > 100){
                tishi_alert("系统打分和店长打分的总和不能超过100！");
                return false;
            }
        }else{
            if(parseInt(sys_score) > 100){
                tishi_alert("系统打分不能超过100！");
                return false;
            }
        }
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
                    if(manage_score != ""){
                        this_obj.parents('tr').find('.assess_result').text(assess_result(sys_score, manage_score));
                    }
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
        if(isNaN(sys_score)){
            tishi_alert("系统打分必须为数字!");
            return false;
        }
        var store_id = $("#store_id").val();
        var staff_id = $("#staff_id").val();
        var month_score_id = $(this).attr("name");
        var manage_score = $("#month_score_val").text();
        if(manage_score != ""){
            var total = parseInt(sys_score) + parseInt(manage_score);
            if(total > 100){
                tishi_alert("系统打分和店长打分的总和不能超过100！");
                return false;
            }
        }else{
            if(parseInt(sys_score) > 100){
                tishi_alert("系统打分不能超过100！");
                return false;
            }
        }
        $.ajax({
            type : 'get',
            url : "/stores/"+ store_id+"/month_scores/update_sys_score",
            data : {
                sys_score : sys_score,
                month_score_id : month_score_id,
                staff_id : staff_id
            },
            success: function(data){
                if(data == "success"){
                    this_obj.hide();
                    this_obj.next().show();
                    $("#sys_score_text").text(sys_score).show();
                    $("#sys_score_input").hide();
                    $("#assess_result").val(assess_result(sys_score, manage_score));
                    $("#current_month_score").text(sys_score);
                }
            }
        });
        return false;
    });

    //验证店长打分和系统打分的和是否超过100
    $("#manage_score_btn_validate").click(function(){
        var manage_score = $("#month_score_manage_score").val();
        if(isNaN(manage_score)){
            tishi_alert("店长打分必须为数字!");
            return false;
        }
        var sys_score = $("#sys_score_text").text();
        var total = parseInt(sys_score) + parseInt(manage_score);
        if(total > 100){
            tishi_alert("系统打分和店长打分的和不能超过100！");
            return false;
        }
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
        if($.trim(reward_num) == ""){
            tishi_alert("提成金额不能为空！");
            return false;
        }
        if(isNaN(reward_num)){
            tishi_alert("提成金额必须为数字!");
            return false;
        }
        if($.trim(deduct_num) == ""){
            tishi_alert("扣款金额不能为空！");
            return false;
        }
        if(isNaN(deduct_num)){
            tishi_alert("扣款金额必须为数字!");
            return false;
        }
        var base_salary = $(this).parents('tr').find(".base_salary_text").text();
        var total_price = parseFloat(base_salary) + parseFloat(reward_num) - parseFloat(deduct_num)
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
                    this_obj.parents('tr').find(".total_price_text").text(total_price);
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
    $(".process_reward").live("click", function(){
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
    $(".process_violation").live("click", function(){
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

    //处理培训
    $(".process_train").live("click", function(){
        if(confirm("确认已通过考核？")){
            var this_obj = $(this);
            var store_id = $("#store_id").val();
            var staff_id = $("#staff_id").val();
            var train_id = $(this).attr("id");
            $.ajax({
                type : 'put',
                url : "/stores/"+ store_id+"/trains/"+ train_id,
                data : {
                    staff_id : staff_id
                },
                success: function(data){
                    if(data == "success"){
                        this_obj.parents('tr').find("span.train_status").text("通过");
                        this_obj.hide();
                        this_obj.next().show();
                    }
                }
            });
            return false;
        }
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
            data : {
                tab:tab
            }
        });
        return false;
    });

    //查询工作记录
    $("#search_work_record").click(function(){
        var start_at = $(this).parents('.search').find("#start_at").val();
        var end_at = $(this).parents('.search').find("#end_at").val();
        if(new Date(start_at) > new Date(end_at)){
            tishi_alert("开始时间必须在结束时间之后!");
            return false;
        }
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
