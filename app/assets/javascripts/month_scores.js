function check_goal(){
    var created  =$("#created").val();
    var ended =$("#ended").val();
    var types_name =[];
    if ((created=="" || created.length==0) && (ended=="" || ended.length )){
        alert("请选择目标销售额的起止日期！");
        return false;
    }
    var carry_out =true;
    $(".popup_body_area div[id *='item']").each(function(){
        if ($(this).find("input").length==1){
            var label =$(this).find("label").html();
            types_name.push(label)
            if ($(this).find("input").val()==0 || $(this).find("input").length==0){
                alert("请输入"+label+"的金额");
                carry_out=false;
                return false
            }
        }else{
            var first=$(this).find("input").first().val();
            if (first!="" || first.length!=0 ){
                var second=$(this).find("input").last().val();
                if(second=="" || second.length==0){
                    alert("请输入"+first+"的金额");
                    carry_out=false;
                    return false;
                }
                if (types_name.indexOf(first)>=0 ){
                    alert("”"+first+"“ 已经存在，请检查");
                    carry_out=false;
                    return false;
                }
                types_name.push(first)
            }
        }
    })
    if(carry_out && confirm("目标销售额不能更改，您确定创建该目标吗？")){
        $("#create_goal").submit();
    }
}

function add_div(){
    var num=$(".popup_body_area div[id *='item']");
    var  str='<div class="item" id=item_'+ num.length+'><input type="text" name="val['+num.length +']" size="12" class="input_s" /><input name="goal['+num.length +']" type="text" /></div>';
    $(num[num.length-1]).after(str);
}