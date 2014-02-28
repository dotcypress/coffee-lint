{$, $$$, View} = require 'atom'

module.exports =
class ResultView extends View

  @content: ->
    @div class: 'coffee-lint tool-panel panel-bottom', =>
      @div class: 'panel-body padded', =>
        @ul outlet: 'errorList', class: 'list-group'

  serialize: ->

  destroy: ->
    @detach()

  render:(errors, editorView) ->
    @errorList.empty()
    for error in errors
      @errorList.append $$$ ->
        @li class: 'list-item', =>
          @span lineNumber: error.lineNumber,
          class: 'error-item icon icon-alert',
          "[#{error.lineNumber}]  #{error.message}"
    @on 'click', '.error-item', ->
      row = $(this).attr 'lineNumber'
      editorView.editor.setCursorBufferPosition [row - 1, 0]
