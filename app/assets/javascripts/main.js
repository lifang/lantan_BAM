// JavaScript Document
//登录默认值
function focusBlur(e){
    $(e).focus(function(){
        var thisVal = $(this).val();
        if(thisVal == this.defaultValue){
            $(this).val('');
        }
    })
    $(e).blur(function(){
        var thisVal = $(this).val();
        if(thisVal == ''){
            $(this).val(this.defaultValue);
        }
    })
}

$(function(){
    focusBlur('.login_box input');//用户信息input默认值
// focusBlur('.item input');//用户信息input默认值
})

//切换
$(function() {
    $('div.tab_head li').bind('click',function(){
        $(this).addClass('hover').siblings().removeClass('hover');
        var index = $('div.tab_head li').index(this);
        $('div.data_body > div').eq(index).show().siblings().hide();
    });
})

//偶数行变色
$(function(){
    $(".data_table > tbody > tr:odd").addClass("tbg");
    $(".data_tab_table > tbody > tr:odd").addClass("tbg");
});

//弹出层
function popup(t){
    var scolltop = document.body.scrollTop|document.documentElement.scrollTop; //滚动条高度
    var doc_height = $(document).height(); //页面高度
    var doc_width = $(document).width(); //页面宽度
    //var win_height = document.documentElement.clientHeight;//jQuery(document).height();
    var win_height = window.height; //窗口高度
    var layer_height = $(t).height(); //弹出层高度
    var layer_width = $(t).width(); //弹出层宽度
    $(t).css('top',scolltop+100);
    $(t).css('left',(doc_width-layer_width)/2);
    $(t).css('display','block');

    if((scolltop+100+layer_height)>doc_height){
        $(".mask").css({
            display:'block',
            height: scolltop+100+layer_height
        })
    }else{
        $(".mask").css({
            display:'block',
            height: doc_height
        })
    }
    $(t+" a.close").live("click",function(){
        $(t).css('display','none');
        $(".mask").css('display','none');
    })
    $(".cancel_btn").live("click",function(){
        $(t).css('display','none');
        $(".mask").css('display','none');
    })
}

//现场施工
$(function(){
    var sitePayHeight = $(".site_pay").height();
    $(".site_pay > h1").css("height",sitePayHeight);

    var siteWorkHeight = $(".site_work").height();
    $(".site_work > h1").css("height",siteWorkHeight);

    var siteInfoHeight = $(".site_info").height();
    $(".site_info > h1").css("height",siteInfoHeight);
});

//向选择框添加产品服务
function add_this(e,name){
    var child="<div id='"+e.value+"'><em>"+name +"</em><a href='javascript:void(0)' class='addre_a'  \n\
   onclick=\"add_one(\'"+e.value +"\')\" id='add_one"+e.value +"'>+</a><span><input name='sale_prod["+e.value +"]' \n\
    type='text' class='addre_input' value='1' id='add_p"+e.value +"' /></span><a href='javascript:void(0)' class='addre_a' \n\
    id='delete_one"+e.value+"'>-</a><a href='javascript:void(0)' class='remove_a' \n\
    onclick='$(this).parent().remove();if($(\"#prod_"+ e.value+"\").length!=0){$(\"#prod_"+ e.value+"\")[0].checked=false;}'>删除</a></div>";
    if ($(e)[0].checked){
        if ($("#add_products #"+e.value).length==0){
            $(".popup_body_fieldset #add_products").append(child);
        }else{
            var num=parseInt($("#add_products #add_p"+e.value).val())+1;
            $("#add_products #add_p"+e.value).val(num);
            $("#add_products #delete_one"+e.value).attr("onclick","delete_one('"+ e.value+"')");
        }
    }else{
        $("#add_products #"+e.value).remove();
    }
}


function add_one(id){
    var num=parseInt($("#add_products #add_p"+id).val())+1;
    $("#add_products #add_p"+id).val(num);
    if (num>=2)
        $("#add_products #delete_one"+id).attr("onclick","delete_one('"+ id+"')");
}

function delete_one(id){
    var num=parseInt($("#add_products #add_p"+id).val())-1;
    if (num==1){
        $("#add_products #delete_one"+id).attr("onclick","");
    }
    $("#add_products #add_p"+id).val(num);
}

function show_center(t){
    var mouse_position = document.body.scrollTop+document.documentElement.scrollTop;
    var doc_height = $(document).height();
    var doc_width = $(document).width();
    var layer_height = $(t).height();
    var layer_width = $(t).width();
    var win_height =  $(window).height();
    $(".mask").css({
        display:'block',
        height:　(layer_height+mouse_position+100)<doc_height ? doc_height+100 : doc_height+(layer_height+100-win_height+50)
    });
    $(t).css('top',mouse_position+100+"px" );
    $(t).css('left',(doc_width-layer_width)/2);
    $(t).css('display','block');
    $(t + " .close").click(function(){
        $(t).css('display','none');
        $(".mask").css('display','none');
    });
}
function before_center(t){
    var mouse_position = document.body.scrollTop+document.documentElement.scrollTop;
    var win_height =  $(window).height();
    var doc_height = $(document).height();
    var doc_width = $(document).width();
    var layer_height = $(t).height();
    var layer_width = $(t).width();
    $(".maskOne").css({
        display:'block',
        height:(layer_height+mouse_position+100)<doc_height ? doc_height+100 : doc_height+(layer_height+100-win_height+50)
    });
    $(t).css('top',mouse_position+100+"px");
    $(t).css('left',(doc_width-layer_width)/2);
    $(t).css('display','block');
    $(t + " .close").click(function(){
        $(t).css('display','none');
        $(".maskOne").css('display','none');
    });
}


//基础数据权限配置 切换
$(function() {
    $('.groupFunc_h li').bind('click',function(){
        $(this).addClass('hover').siblings().removeClass('hover');
        var index = $('.groupFunc_h li').index(this);
        $('.groupFunc_b > div').eq(index).show().siblings().hide();
    });
});

//排序切换箭头
function sort_change(obj){
    if($(obj).attr("class") == "sort_u"){
        $(obj).attr("class", "sort_d");
    }else if($(obj).attr("class") == "sort_d"){
        $(obj).attr("class", "sort_u");
    }else if($(obj).attr("class") == "sort_u_s"){
        $(obj).attr("class", "sort_d_s");
    }else{
        $(obj).attr("class", "sort_u_s");
    }
}


//提示错误信息
function tishi_alert(message){
    $(".alert_h").html(message);
    var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = document.documentElement.clientHeight;//jQuery(document).height();
    var z_layer_height = $(".tab_alert").height();
    $(".tab_alert").css('top',(win_height-z_layer_height)/2 + scolltop);
    var doc_width = $(document).width();
    var layer_width = $(".tab_alert").width();
    $(".tab_alert").css('left',(doc_width-layer_width)/2);
    $(".tab_alert").css('display','block');
    jQuery('.tab_alert').fadeTo("slow",1);
    $(".tab_alert .close").click(function(){
        $(".tab_alert").css('display','none');
    })
    setTimeout(function(){
        jQuery('.tab_alert').fadeTo("slow",0);
    }, 4000);
    setTimeout(function(){
        $(".tab_alert").css('display','none');
    }, 4000);
}

//center popup div
function center_popup_div(ele){
    var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = document.documentElement.clientHeight;
    var z_layer_height = $(ele).height();
    $(ele).css('top',(win_height-z_layer_height)/2 + scolltop);
}

// 点击取消按钮隐藏层
function hide_mask(t){
    $(t).css('display','none');
    $(".mask").css('display','none');
}