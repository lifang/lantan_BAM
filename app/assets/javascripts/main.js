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
    focusBlur('.item input');//用户信息input默认值
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
function popup(t,b){
    var doc_height = $(document).height();
    var doc_width = $(document).width();
    //var win_height = $(window).height();
    //var win_width = $(window).width();
	
    var layer_height = $(t).height();
    var layer_width = $(t).width();
	
    //tab
    $(b).bind('click',function(){
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
    )
    $(".close").click(function(){
        $(t).css('display','none');
        $(".mask").css('display','none');
    })
    $(".cancel_btn").click(function(){
        $(t).css('display','none');
        $(".mask").css('display','none');
    })
}

//入库弹出层
$(function(){
    popup(".ruku_tab",".rk_btn");//入库
    popup(".chuku_tab",".ck_btn");//出库
    popup(".dinghuo_tab",".dh_btn");//订货
    popup(".beizhu_tab",".bz_btn");//备注
    popup(".add_tab",".add_btn");//添加XXX
    popup(".see_tab",".see_btn");//查看XXX
})


//现场施工
$(function(){
    var sitePayHeight = $(".site_pay").height();
    $(".site_pay > h1").css("height",sitePayHeight);
	
    var siteWorkHeight = $(".site_work").height();
    $(".site_work > h1").css("height",siteWorkHeight);
	
    var siteInfoHeight = $(".site_info").height();
    $(".site_info > h1").css("height",siteInfoHeight);
})


//请求加载产品或服务类别
function load_types(store_id){
    var types=$("#sale_types option:checked").val();
    var name=$("#sale_name").val();
    if (types != "" || name != ""){
        $.ajax({
            async:true,
            type : 'post',
            dataType : 'script',
            url : "/stores/"+ store_id+"/sales/load_types",
            data : {
                sale_types : types,
                sale_name : name
            }
        });
    }else{
        alert("请选择类型或填写名称！");
    }
}

//向选择框添加产品服务
function add_this(e){
    var child="<div ><em>"+$(e).html() +"</em><a href='#' class='addre_a'>+</a><span><input name='product["+e.value +"]' type='text' class='addre_input' value='1' />\n\
               </span><a href='#' class='addre_a'>-</a><a href='#' class='remove_a'>删除</a></div></div>";
    $(".popup_body_fieldset #add_products").append(child);
}