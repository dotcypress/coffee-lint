{$, $$$, View} = require 'atom'

module.exports =
class ResultView extends View

  @content: ->
    @div class: "panel coffee-lint", =>
      @div class: "panel-heading", 'Coffee Lint'
      @div class: "panel-body", =>
        @ul outlet: 'errorList', class: 'list-group'

  serialize: ->

  destroy: ->
    @detach()

  render:(errors, editorView) ->
    @errorList.empty()
    for error in errors
      @errorList.append $$$ ->
        @li class: 'list-item', =>
          icon = if error.level is 'error' then 'alert' else 'info'
          @span lineNumber: error.lineNumber,
          class: "result-item icon icon-#{icon} lint-#{error.level}",
          "[#{error.lineNumber}]  #{error.message}"
    @on 'click', '.result-item', ->
      row = $(this).attr 'lineNumber'
      editorView.editor.setCursorBufferPosition [row - 1, 0]
