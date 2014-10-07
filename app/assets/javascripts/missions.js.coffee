jQuery ->
  $('#missions-table').dataTable
    ajax: $('#missions-table').data('source')
    lengthMenu: [ [10, 25, 50, 999999], [10, 25, 50, "All"] ]
    pagingType: 'full_numbers'
    processing: true
    serverSide: true