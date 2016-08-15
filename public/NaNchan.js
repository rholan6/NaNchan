$(document).ready(function() {
    $('#submitPost').click(function() {
        console.log('Posting thread');
        $.post('/newBread', {subject: $('#topicBox').val(), poster: $('#nameBox').val(), imgurl: $('#imgBox').val(), content: $('#contentBox').val()});
        $('#topicBox').val('');
        $('#nameBox').val('');
        $('#imgBox').val('');
        $('#contentBox').val('');
        console.log('Posted thread');
    });
});