expect = require('chai').expect

Robot       = require('hubot/src/robot')
TextMessage = require('hubot/src/message').TextMessage

describe 'auth-middleware', ->

  robot = {}
  adapter = {}
  middleware = {}
  adminUser = {}
  otherUser = {}

  beforeEach (done) ->
    process.env.HUBOT_AUTH_ADMIN = 1
    process.env.HUBOT_LOG_LEVEL = 'warning'  # middleware sends INFO logs
    process.env.HUBOT_AUTH_MIDDLEWARE_ENVIRONMENT = 'x'
    process.env.HUBOT_AUTH_MIDDLEWARE_ENVIRONMENT_REPLY = 'true'

    robot = new Robot null, "mock-adapter", false

    robot.adapter.on "connected", ->
      require("hubot-auth/src/auth")(@robot)
      require("../src/auth-middleware")(@robot)
      require("../test/auth-middleware-test-listeners")(@robot)

      adminUser = robot.brain.userForId '1', {
        name: 'adminUser'
        room: '#test'
      }
      otherUser = robot.brain.userForId '2', {
        name: 'otherUser'
        room: '#x'
      }
      adapter = robot.adapter
      middleware = robot.middleware

    robot.run()
    done()

  afterEach ->
    robot.shutdown()

  it 'does nothing when listener.options is empty', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /no options success/
      done()

    adapter.receive(new TextMessage adminUser, "amTest no options")

  it 'does nothing when listener.options is oddly formatted', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /strange options success/
      done()

    adapter.receive(new TextMessage adminUser, "amTest strange options")

  it 'replies with error when environments are non-matching (env var dependent)', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /Rejecting/
      done()

    adapter.receive(new TextMessage adminUser, "amTest reject environment")

  it 'replies with error when rooms are non-matching', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /Rejecting/
      done()

    adapter.receive(new TextMessage adminUser, "amTest reject room")

  it 'replies with error when roles are non-matching', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /Rejecting/
      done()

    adapter.receive(new TextMessage adminUser, "amTest reject role")

  it 'allows command if environments match', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /allow environment success/
      done()

    adapter.receive(new TextMessage adminUser, "amTest allow environment")

  it 'allows command if rooms match', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /allow room success/
      done()

    adapter.receive(new TextMessage otherUser, "amTest allow room")

  it 'allows command if roles match', (done) ->
    adapter.on "reply", (envelope, strings) ->
      expect(strings[0]).to.match /allow role success/
      done()

    adapter.receive(new TextMessage adminUser, "amTest allow role")

