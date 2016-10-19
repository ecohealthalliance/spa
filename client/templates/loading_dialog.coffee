centerLoadingSpinner = ->
  loadingContainerWidth = $('.loading-content').width() or 100
  leftSideBarWidth = $('#sidebar').width()
  rightSideBarWidth = $('.sidebarRight .sidebar-content').width()
  mapViewWidth = $(document).width() - leftSideBarWidth - rightSideBarWidth
  console.log mapViewWidth
  loadingSpinnerPosition = mapViewWidth / 2 - loadingContainerWidth / 2 + rightSideBarWidth
  $('.loading-content').css 'right', "#{loadingSpinnerPosition}px"

Template.loadingDialog.onRendered ->
  centerLoadingSpinner()
  $(window).resize ->
    centerLoadingSpinner()

Template.loadingDialog.onDestroyed ->
  $(window).off 'resize'
