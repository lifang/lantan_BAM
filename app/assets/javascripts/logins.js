function check_login() {
    if ($.trim($("#user_name").val()) == null || $.trim($("#user_name").val()) == ""
        || $.trim($("#user_password").val()) == null || $.trim($("#user_password").val()) == "") {
        tishi_alert("请输入用户名密码");
        return false;
    }
    return true;
}