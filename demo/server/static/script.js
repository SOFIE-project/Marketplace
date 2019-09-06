$(document).ready( function () {
    $('#table').DataTable();
});

$(document).ready(function() {
    $(".clickable").click(function() {
        window.location = $(this).data("href");
    })
})