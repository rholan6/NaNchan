$(document).ready(function () {
    $('#submitPost').click(function () {
        $.post('/newPost', {poster: $('#nameBox').val(), imgurl: $('#imgBox').val(), content: $('#contentBox').val(), thread_id: $('#threadnum').html()});
        $('#nameBox').val('');
        $('#imgBox').val('');
        $('#contentBox').val('');
    });
});