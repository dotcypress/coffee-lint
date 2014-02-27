CoffeeLint = require '../lib/coffee-lint'

describe "CoffeeLint", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('coffeeLint')

  describe "when the coffee-lint:lint event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.coffee-lint')).not.toExist()

      atom.workspaceView.trigger 'coffee-lint:lint'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.coffee-lint')).toExist()
        atom.workspaceView.trigger 'coffee-lint:lint'
        expect(atom.workspaceView.find('.coffee-lint')).not.toExist()
