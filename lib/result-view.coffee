{$, $$$, View} = require 'atom'

module.exports =
class ResultView extends View

  @content: ->
    @div class: 'coffee-lint', =>
      @div outlet: 'resizeHandle', class: 'resize-handle'
      @div class: "panel", =>
        @div class: "panel-heading", =>
          @div class: 'pull-right', =>
            @span outlet: 'closeButton', class: 'close-icon'
          @span 'Coffee Lint'
        @div class: 'panel-body', =>
          @ul outlet: 'noProblemsMessage', class: 'background-message', =>
            @li 'No Problems ;)'
          @ul outlet: 'errorList', class: 'list-group'

  initialize: (state) ->
    @height state?.height
    @closeButton.on 'click', => @detach()
    @resizeHandle.on 'mousedown', (e) => @resizeStarted e

  serialize: ->
    height: @height()

  resizeStarted: ({pageY}) ->
    @resizeData =
      pageY: pageY
      height: @height()
    $(document.body).on 'mousemove', @resizeView
    $(document.body).on 'mouseup', @resizeStopped

  resizeStopped: ->
    $(document.body).off 'mousemove', @resizeView
    $(document.body).off 'mouseup', @resizeStopped

  resizeView: ({pageY}) =>
    @height @resizeData.height + @resizeData.pageY - pageY

  render: (errors = [], editorView) ->
    if errors.length > 0
      @noProblemsMessage.hide()
    else
      @noProblemsMessage.show()
    @errorList.empty()
    for error in errors
      @errorList.append $$$ ->
        @li class: "list-item lint-#{error.level}", l: error.lineNumber, =>
          icon = if error.level is 'error' then 'alert' else 'info'
          @span class: "icon icon-#{icon}"
          @span class: 'text-smaller',
            "Line: #{error.lineNumber} - #{error.message}"

    @on 'click', '.list-item',  ->
      row = $(this).attr 'l'
      editorView?.editor.setCursorBufferPosition [row - 1, 0]
