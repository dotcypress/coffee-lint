{$, $$$, View} = require 'atom'

module.exports =
class ResultView extends View

  @content: ->
    @div class: "panel coffee-lint", =>
      @div class: "panel-heading", =>
        @div class: 'pull-right', =>
          @span outlet: 'closeButton', class: 'close-icon'
        @span 'Coffee Lint'
      @div class: "panel-body", =>
        @ul outlet: 'noProblemsMessage', class: 'background-message', =>
          @li 'No Problems ;)'
        @ul outlet: 'errorList', class: 'list-group'

  initialize: ->
    @closeButton.on 'click', => @detach()

  destroy: ->
    @detach()

  render:(errors = [], editorView) ->
    if errors.length > 0
      @noProblemsMessage.hide()
    else
      @noProblemsMessage.show()
    @errorList.empty()
    for error in errors
      @errorList.append $$$ ->
        @li class: "list-item lint-#{error.level}", linenumber: error.lineNumber, =>
          icon = if error.level is 'error' then 'alert' else 'info'
          @span class: "icon icon-#{icon}"
          @span class: 'text-smaller', "Line: #{error.lineNumber} - #{error.message}"
    @on 'click', '.list-item',  ->
      row = $(this).attr 'linenumber'
      editorView?.editor.setCursorBufferPosition [row - 1, 0]
