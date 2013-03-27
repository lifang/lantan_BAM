$(document).ready(function(){
    $("#mat_code").focus();
    $("#mat_code").live('keyup', function(event){
        var codeVal = $(this).val();
        var action_name = $(this).attr("data_action");
        var e = event ? event : window.event
        if(e.keyCode==13){
            $.get("/get_material", {
                code: codeVal,
                action_name: action_name
            })
            .done(function(data) {
                if(data=="no results"){
                    $(".search_alert").show();
                }
                else{
                    $(".search_alert").hide();
                    $(".mat-out-list").find(".newTr_red").removeClass("newTr_red");
                    $(".mat_code").each(function(){   
                        if($(this).text()==codeVal){
                            $(this).parent('tr').addClass("newTr_red");
                            var ori_num = parseInt($(this).siblings(".mat_item_num").text());
                            var var_num = parseInt($(this).siblings(".mat_item_num").next().val());
                            $(this).siblings(".mat_item_num").text(ori_num+1);
                            $(this).siblings(".hidden_mat_id").val(var_num+1);
                            return false;
                        }
                    });
                    if($(".mat-out-list").find(".newTr_red").length==0){
                        $(".mat-out-list").append(data);
                    }
                    $("#mat_code").val('');
                    $("#mat_code").focus();
                }
            });
        }
    });
    $("#staff_id").live('change', function(){
        var staff_id = $(this).val();
        $.get("/save_cookies", {
            staff_id: staff_id
        })
        .done(function(data) {})
    })

    setTimeout( function(){
        $('.mat_notice' ).fadeOut();
    }, 3000 );

});

function changeNum(obj){
    var ori_num = $(obj).parent("td").siblings(".hidden_mat_id").val();
    $(obj).parent("td").siblings(".mat_item_num").hide();
    $(obj).parent("td").siblings(".hidden_mat_id").attr('disabled', true);
    $(obj).parent("td").prev(".num_box").find("input").attr('disabled', false).val(ori_num).end().show();
}

function removeRow(obj){
    $(obj).parents("tr").html('').hide();
}