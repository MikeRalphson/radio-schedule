// Asynchronously load the synopses
$(function() {

  $("tbody tr").each(function( index ) {
    var episode_pid = $(this).data('episode-pid');
    var row = this;

    $.getJSON( "/episodes/"+episode_pid, function( data ) {
      $(row).find('td').eq(3).text(data['synopses']['short'] || '');
      $(row).find('td').eq(4).text(data['synopses']['medium'] || '');
      $(row).find('td').eq(5).text(data['synopses']['long'] || '');
    });

  });

});
