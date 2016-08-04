# Description:
#   Auth-middleware test listeners - used in the test suite
#
# Dependencies:
#
# Configuration:
#
# Commands:
#
module.exports = (robot) ->
  robot.hear /amTest no options/, (msg) ->
    msg.reply "no options success"

  robot.hear /amTest strange options/, {"id":"someId","auth":"weirdAttribute"}, (msg) ->
    msg.reply "strange options success"

  envRejOptions = {"id":"reject-environment", "auth": "true", "env": "notThisEnv"}
  robot.hear /amTest reject environment/, envRejOptions, (msg) ->
    msg.reply "reject environment fail"

  roomRejOptions = {"id":"reject-room", "auth":"true", "rooms":"notThisRoom"}
  robot.hear /amTest reject room/, roomRejOptions, (msg) ->
    msg.reply "reject room fail"

  roleRejOptions = {"id":"reject-role", "auth":"true", "roles":"notThisRole"}
  robot.hear /amTest reject role/, roleRejOptions, (msg) ->
    msg.reply "reject role fail"

  envAllOptions = {"id":"allow-environment", "auth":"true", "env":"x"}
  robot.hear /amTest allow environment/, envAllOptions, (msg) ->
    msg.reply "allow environment success"

  roomAllOptions = {"id":"allow-room", "auth":"true", "rooms":["#x","#y"]}
  robot.hear /amTest allow room/, roomAllOptions, (msg) ->
    msg.reply "allow room success"

  roleAllOptions = {"id":"allow-role", "auth":"true", "roles":["wheel","admin","sudo"]}
  robot.hear /amTest allow role/, roleAllOptions, (msg) ->
    msg.reply "allow role success"

