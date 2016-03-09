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


// Handle loading the edit modal dialogue box
$('#edit-modal').on('show.bs.modal', function (event) {
  var modal = $(this);
  var row = $(event.relatedTarget).parents("tr");
  var broadcast_pid = row.data('broadcast-pid');
  
  $('#edit-modal-save').attr('disabled', 'disabled');
  $('#edit-modal-spinner').removeClass('hidden');

  $('#modal-title').text('Edit Broadcast '+broadcast_pid);
  $('#edit-modal-published-start-date').val('');
  $('#edit-modal-published-start-time').val('');
  $('#edit-modal-published-end-date').val('');
  $('#edit-modal-published-end-time').val('');
  $('#edit-modal-accurate-start-date').val('');
  $('#edit-modal-accurate-start-time').val('');
  $('#edit-modal-accurate-end-date').val('');
  $('#edit-modal-accurate-end-time').val('');

  $.getJSON("/broadcasts/"+broadcast_pid, function( data ) {
    var published_start = data['start_time'].split(/\s+/);
    $('#edit-modal-published-start-date').val(published_start[0]);
    $('#edit-modal-published-start-time').val(published_start[1]);

    var published_end = data['end_time'].split(/\s+/);
    $('#edit-modal-published-end-date').val(published_end[0]);
    $('#edit-modal-published-end-time').val(published_end[1]);

    if (data['accurate_start']) {
      var accurate_start = data['accurate_start'].split(/\s+/);
      $('#edit-modal-accurate-start-date').val(accurate_start[0]);
      $('#edit-modal-accurate-start-time').val(accurate_start[1]);
    } else {
      $('#edit-modal-accurate-start-date').val(published_start[0]);
      $('#edit-modal-accurate-start-time').val(published_start[1]);
    }

    if (data['accurate_end']) {
      var accurate_end = data['accurate_end'].split(/\s+/);
      $('#edit-modal-accurate-end-date').val(accurate_end[0]);
      $('#edit-modal-accurate-end-time').val(accurate_end[1]);
    } else {
      $('#edit-modal-accurate-end-date').val(published_end[0]);
      $('#edit-modal-accurate-end-time').val(published_end[1]);
    }

    // Allow pressing save now
    $('#edit-modal-save').removeAttr('disabled');
  }).always(function() {
    $('#edit-modal-spinner').addClass('hidden');
  });


  // Handle pressing the save button
  $('#edit-modal-save').click(function (event) {
    $('#edit-modal-save').attr('disabled', 'disabled');
    $('#edit-modal-spinner').removeClass('hidden');

    data = {
      accurate_start: $('#edit-modal-accurate-start-date').val() + ' ' + $('#edit-modal-accurate-start-time').val(),
      accurate_end: $('#edit-modal-accurate-end-date').val() + ' ' + $('#edit-modal-accurate-end-time').val()
    }

    $.post("/broadcasts/"+broadcast_pid, data, function() {
      $('#edit-modal').modal('hide');
    }).always(function() {
      $('#edit-modal-save').removeAttr('disabled');
      $('#edit-modal-spinner').addClass('hidden');
    });

  });

})

