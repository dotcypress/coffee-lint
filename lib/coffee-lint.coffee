coffeelint = require './linter'

module.exports =

  activate: (state) ->
    atom.workspaceView.command "coffee-lint:lint", => @lint()

  lint: ->
    {editor, gutter} = atom.workspaceView.getActiveView()
    gutter.removeClassFromAllLines 'coffee-error'
    return unless editor
    source = editor.getText()
    errors = coffeelint.lint source
    for error in errors
      gutter.addClassToLine error.lineNumber - 1, 'coffee-error'
