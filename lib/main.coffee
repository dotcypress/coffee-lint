CoffeeLint = require './coffee-lint'

module.exports =

  configDefaults:
    lintOnSave: true

  activate: ->
    @linter = new CoffeeLint()

  deactivate: ->
    @linter.destroy()
