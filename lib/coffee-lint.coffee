{Subscriber} = require 'emissary'
coffeelinter = require './linter'

module.exports =

  class CoffeeLint
    Subscriber.includeInto(this)

    constructor: ->
      atom.workspaceView.command "coffee-lint:lint", =>
        @lint atom.workspaceView.getActiveView()
      atom.workspaceView.eachEditorView (editorView) =>
        @handleBufferEvents editorView

    destroy: ->
      @unsubscribe()

    handleBufferEvents: (editorView) ->
      buffer = editorView.editor.getBuffer()
      @lint editorView

      @subscribe buffer, 'will-be-saved', =>
        buffer.transact =>
          if atom.config.get('coffee-lint.lintOnSave')
            @lint editorView

      @subscribe buffer, 'destroyed', =>
        @unsubscribe(buffer)

    lint: (editorView) ->
      {editor, gutter} = editorView
      return if editor.getGrammar().scopeName isnt "source.coffee"
      gutter.removeClassFromAllLines 'coffee-error'
      source = editor.getText()
      errors = coffeelinter.lint source
      for error in errors
        gutter.addClassToLine error.lineNumber - 1, 'coffee-error'
