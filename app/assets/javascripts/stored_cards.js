// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function(){

   //库存成本统计选择月份提交
   $("#statistics_month_select").change(function(){
      $(this).parents('form').submit();
      return false;
   });

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
   })

});
