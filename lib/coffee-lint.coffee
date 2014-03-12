{Subscriber} = require 'emissary'
ResultView = require './result-view'
coffeelinter = require './vendor/linter'
fs = require 'fs'
path = require 'path'
_ = require 'underscore-plus'

module.exports =

  class CoffeeLint
    Subscriber.includeInto this

    constructor: ->
      @resultView = new ResultView()
      atom.workspaceView.command "coffee-lint:lint-current-file", =>
        @lint()
      atom.workspaceView.command "coffee-lint:toggle-results-panel", =>
        if @resultView.hasParent()
          @resultView.detach()
        else
          atom.workspaceView.prependToBottom @resultView
          @lint()

      atom.workspaceView.on 'pane-container:active-pane-item-changed', =>
        @lint() if @resultView.hasParent()
      atom.workspaceView.eachEditorView (editorView) =>
        @handleBufferEvents editorView

    deactivate: ->
      atom.workspaceView.off 'core:cancel core:close'
      atom.workspaceView.off 'pane-container:active-pane-item-changed'

    destroy: ->
      @unsubscribe()

    handleBufferEvents: (editorView) ->
      buffer = editorView.editor.getBuffer()
      @lint editorView

      @subscribe buffer, 'saved', (buffer) ->
        if buffer.previousModifiedStatus and atom.config.get 'coffee-lint.lintOnSave'
          try
            @lint editorView
          catch e
            console.log e

      editorView.editor.on 'contents-modified', =>
        if atom.config.get 'coffee-lint.continuousLint'
          try
            @lint editorView
          catch e
            console.log e

      @subscribe buffer, 'destroyed', =>
        @unsubscribe buffer

    lint: (editorView = atom.workspaceView.getActiveView()) ->
      return if editorView.coffeeLintPending
      {editor, gutter} = editorView
      return @resultView.render() if not editor or editor.getGrammar().scopeName isnt "source.coffee"
      editorView.coffeeLintPending = yes
      gutter.removeClassFromAllLines 'coffee-error'
      gutter.removeClassFromAllLines 'coffee-warn'
      gutter.find('.line-number .icon-right').attr 'title', ''
      source = editor.getText()
      try
        localFile = path.join atom.project.path, 'coffeelint.json'
        configObject = atom.config.get 'coffee-lint.config'
        if fs.existsSync localFile
          configObject = fs.readFileSync localFile, 'UTF8'
        config = JSON.parse configObject
      catch e
        console.log e
      errors = coffeelinter.lint source, config
      errors = _.sortBy errors, 'level'
      for error in errors
        row = gutter.find gutter.getLineNumberElement(error.lineNumber - 1)
        row.find('.icon-right').attr 'title', error.message
        row.addClass "coffee-#{error.level}"

      @resultView.render errors, editorView
      editorView.coffeeLintPending = no
