function check_login() {
    if ($.trim($("#user_name").val()) == null || $.trim($("#user_name").val()) == ""
        || $.trim($("#user_password").val()) == null || $.trim($("#user_password").val()) == "") {
        tishi_alert("请输入用户名密码");
        return false;
    }
    return true;
}

$(document).ready(function(){
    $("#forgot_password_area .cancel_btn, #forgot_password_area .close").click(function(){
        $("#telphone").val('');
        $("#validate_code").val('');
        $('.mask').hide();
        $("#forgot_password_area").hide();
        removeDisable();
        return false;
    });

    $("#forgot_password").click(function(){
        popup("#forgot_password_area");
        return false;
    });

    $("#send_validate_code").click(function(){
        var telphone = $("#telphone").val();
        if($.trim(telphone) == ''){
            tishi_alert("手机号码不能为空!");
            return false;
        }
        $.ajax({
            type : 'get',
            url : "/logins/send_validate_code",
            data : {
                telphone : telphone
            },
            beforeSend:function(xhr){
            //$('#send_validate_code').attr("disabled",true)
            },
            complete:function(data,status){
                if(status=="success"){
                    //$('#send_validate_code').removeClass("confirm_btn");
                    if(data.responseText == "success"){
                        $("#send_validate_code").attr("class", "cancel_btn");
                        $('#send_validate_code').attr("disabled",true);
                        setTimeout("removeDisable()",30000);
                        tishi_alert("短信发送成功，注意查收验证码。若未收到短信，请30秒后再次请求");
                    }else{
                        tishi_alert(data.responseText + "若未收到短信，请30秒后再次请求");
                    }
                }
            }
        });
        return false;
    });

    $("#forgot_password_btn").click(function(){
        var telphone = $("#telphone").val();
        var validate_code = $("#validate_code").val();
        if($.trim(telphone) == ''){
            tishi_alert("手机号码不能为空!");
            return false;
        }
        if($.trim(validate_code) == ''){
            tishi_alert("验证码不能为空!");
            return false;
        }
        $(this).parents('form').submit();
        $(this).attr('disabled', 'disabled');
    })
});
function removeDisable(){
    $("#send_validate_code").attr("disabled",false);
    $("#send_validate_code").attr("class", "confirm_btn");
}


function check_phone(){
    if ($.trim($("#login_name").val()) == null || $.trim($("#login_name").val()) == ""
        || $.trim($("#login_pwd").val()) == null || $.trim($("#login_pwd").val()) == "") {
        tishi_alert("请输入用户名和密码");
        return false;
    }else{
        $("#phone_form").submit();
    }
}
