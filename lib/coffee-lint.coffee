{Subscriber} = require 'emissary'
ResultView = require './result-view'
coffeelinter = require './vendor/linter'
fs = require 'fs'
path = require 'path'

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
      @lint editorView, false

      @subscribe buffer, 'saved', =>
        buffer.transact =>
          if atom.config.get('coffee-lint.lintOnSave')
            try
              @lint editorView
            catch e
              console.log e

      editorView.editor.on 'contents-modified', =>
        if atom.config.get('coffee-lint.continuousLint')
          try
            @lint editorView, false
          catch e
            console.log e

      @subscribe buffer, 'destroyed', =>
        @unsubscribe(buffer)


    lint: (editorView, showPanel = true) ->
      {editor, gutter} = editorView
      return unless editor
      return if editor.getGrammar().scopeName isnt "source.coffee"

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
      for error in errors
        row = gutter.find gutter.getLineNumberElement(error.lineNumber - 1)
        row.find('.icon-right').attr 'title', error.message
        row.addClass "coffee-#{error.level}"

      @resultView?.destroy() if errors.length is 0
      @resultView = @resultView or new ResultView()
      @resultView.render errors, editorView
      atom.workspaceView.prependToBottom @resultView if errors.length isnt 0 and showPanel
