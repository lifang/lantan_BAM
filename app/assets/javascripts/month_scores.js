function check_goal(){
    var created  =$("#created").val();
    var ended =$("#ended").val();
    if ((created=="" || created.length==0) && (ended=="" || ended.length )){
        alert("请选择目标销售额的起止日期！")
    }
    if(confirm("目标销售额不能更改，您确定创建该目标吗？")){
        $("#create_goal").submit();
    }
}