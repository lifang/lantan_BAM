// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function(){

    //查看员工绩效统计
    $(".staff_month_score_detail").click(function(){
        var id = $(this).attr("id");
        var store_id = $("#store_id").val();
        $.ajax({
            async:true,
            type : 'get',
            dataType : 'script',
            url : "/stores/"+ store_id+"/staff_manages/"+ id
        });
        return false;
    });

    //员工绩效  根据年份统计
    $("#statistics_year").live("change", function(){
        var year = $(this).val();
        var id = $(this).attr("name");
        var store_id = $("#store_id").val();
        $.ajax({
            type : 'get',
            url : "/stores/"+ store_id+"/staff_manages/get_year_staff_hart",
            data : {
                year:year,
                id : id
            },
            success: function(data){
                $("#staff_month_chart_detail").find(".tj_pic").find('img').attr("src", data);
            }
        });
        return false;
    });

    //按年份统计平均水平
    $("#statistics_year").change(function(){
        $(this).parents('form').submit();
        return false;
    });

});

function check_goal(e){
    var created  =$("#created").val();
    var ended =$("#ended").val();
    var types_name =[];
    if (created=="" || created.length==0 || ended=="" || ended.length==0 || ended < created ){
        tishi_alert("请选择目标销售额的起止日期，且开始日期小于结束日期");
        return false;
    }
    var carry_out =true;
    $(".popup_body_area div[id *='item']").each(function(){
        if ($(this).find("input").length==1){
            var label =$(this).find("label").html();
            types_name.push(label)
            if ($(this).find("input").val()==0 || $(this).find("input").val().length==0 || isNaN(parseFloat($(this).find("input").val()))){
                tishi_alert("请输入"+label+"的金额,且为数值");
                carry_out=false;
                return false
            }
        }else{
            var first=$(this).find("input").first().val();
            if (first!="" || first.length!=0 ){
                var second=$(this).find("input").last().val();
                if(second=="" || second.length==0 || isNaN(parseFloat(second)) ){
                    tishi_alert("请输入"+first+"的金额,且为数值");
                    carry_out=false;
                    return false;
                }
                if (types_name.indexOf(first)>=0 ){
                    tishi_alert("”"+first+"“ 已经存在，请检查");
                    carry_out=false;
                    return false;
                }
                types_name.push(first)
            }
        }
    })
    if(carry_out && confirm("目标销售额不能更改，您确定创建该目标吗？")){
        $(e).removeAttr("onclick");
        $("#create_goal").submit();
    }
}

function add_div(){
    var num=$(".popup_body_area div[id *='item']");
    var  str='<div class="item" id=item_'+ num.length+'><input type="text" name="val['+num.length +']" size="12" class="input_s" /><input name="goal['+num.length +']" type="text" /></div>';
    $(num[num.length-1]).after(str);
}
