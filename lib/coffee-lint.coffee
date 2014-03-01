{Subscriber} = require 'emissary'
ResultView = require './result-view'
coffeelinter = require './vendor/linter'

module.exports =

  class CoffeeLint
    Subscriber.includeInto(this)

    constructor: ->
      atom.workspaceView.command "coffee-lint:lint", =>
        @lint atom.workspaceView.getActiveView()
      atom.workspaceView.on 'core:cancel core:close', (event) =>
        @resultView?.detach()
      atom.workspaceView.on 'pane-container:active-pane-item-changed', =>
        @resultView?.detach()
      atom.workspaceView.eachEditorView (editorView) =>
        @handleBufferEvents editorView

    deactivate: ->
      tom.workspaceView.off 'core:cancel core:close'
      tom.workspaceView.off 'pane-container:active-pane-item-changed'

    destroy: ->
      @unsubscribe()

    handleBufferEvents: (editorView) ->
      buffer = editorView.editor.getBuffer()
      @lint editorView

      @subscribe buffer, 'saved', =>
        buffer.transact =>
          if atom.config.get('coffee-lint.lintOnSave')
            try
              @lint editorView, null, true
            catch e
              console.log e
      @subscribe buffer, 'destroyed', =>
        @unsubscribe(buffer)

    lint: (editorView) ->
      {editor, gutter} = editorView
      return unless editor
      return if editor.getGrammar().scopeName isnt "source.coffee"

      @resultView?.destroy()

      gutter.removeClassFromAllLines 'coffee-error'
      gutter.removeClassFromAllLines 'coffee-warn'
      source = editor.getText()
      try
        config = JSON.parse atom.config.get('coffee-lint.config')
      catch e
        console.log e
      errors = coffeelinter.lint source, config
      return if errors.length is 0
      @resultView = new ResultView(errors)
      @resultView.render errors, editorView
      atom.workspaceView.prependToBottom @resultView
      for error in errors
        gutter.addClassToLine error.lineNumber - 1, "coffee-#{error.level}"
