ResultView = require './result-view'
coffeelinter = require './vendor/linter'
fs = require 'fs'
path = require 'path'
_ = require 'underscore-plus'

resultView = null

activate = (state) ->
  resultView = new ResultView(state)

  atom.workspaceView.command "coffee-lint:lint-current-file", ->
    lint()

  atom.workspaceView.command "coffee-lint:toggle-results-panel", ->
    return unless resultView
    if resultView.hasParent()
      resultView.detach()
    else
      atom.workspaceView.prependToBottom resultView
      lint()

  atom.workspaceView.on 'pane-container:active-pane-item-changed', ->
    lint() if resultView.hasParent()

  atom.workspaceView.eachEditorView (editorView) ->
    handleBufferEvents editorView

deactivate = ->
  atom.workspaceView.off 'core:cancel core:close'
  atom.workspaceView.off 'pane-container:active-pane-item-changed'
  atom.workspaceView.command "coffee-lint:lint-current-file", ->
  atom.workspaceView.command "coffee-lint:toggle-results-panel", ->
  resultView.detach()
  resultView = null

serialize = ->
  resultView.serialize()

handleBufferEvents = (editorView) ->
  buffer = editorView.editor.getBuffer()
  lint editorView

  buffer.on 'saved', (buffer) ->
    lintOnSave = atom.config.get 'coffee-lint.lintOnSave'
    if buffer.previousModifiedStatus and lintOnSave
      try
        lint editorView
      catch e
        console.log e

  buffer.on 'destroyed', ->
    buffer.off 'saved'
    buffer.off 'destroyed'

  editorView.editor.on 'contents-modified', ->
    if atom.config.get 'coffee-lint.continuousLint'
      try
        lint editorView
      catch e
        console.log e

lint = (editorView = atom.workspaceView.getActiveView()) ->
  return if editorView?.coffeeLintPending
  {editor, gutter} = editorView
  return unless editor
  isCoffeeFile = editor.getGrammar().scopeName is "source.coffee"
  return resultView.render() unless isCoffeeFile
  editorView.coffeeLintPending = yes
  gutter.removeClassFromAllLines 'coffee-error'
  gutter.removeClassFromAllLines 'coffee-warn'
  gutter.find('.line-number .icon-right').attr 'title', ''
  source = editor.getText()
  try
    localFile = path.join atom.project.path, 'coffeelint.json'
    configObject = {}
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

  resultView.render errors, editorView
  editorView.coffeeLintPending = no

module.exports =
  configDefaults:
    lintOnSave: true,
    continuousLint: true,
  activate: activate
  deactivate: deactivate
  serialize: serialize
