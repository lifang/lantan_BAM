/**
 * Created with JetBrains RubyMine.
 * User: alec
 * Date: 13-1-28
 * Time: 下午4:44
 * To change this template use File | Settings | File Templates.
 */
function add_material_remark(material_id){
    alert(material_id);
    var remark = "remark";
    $.ajax({
        url:"/materials/"+material_id + "/remark",
        dataType:"json",
        type:"GET",
        data:"remark="+remark,
        success: function(data,status){
           alert(status);
        }
    })
}