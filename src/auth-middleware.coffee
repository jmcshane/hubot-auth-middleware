# Description:
#   Auth-middleware adds listener-middleware for command access controls
#
#   Auth-middleware adds listener-middleware that checks listener.options for
#   command access control defined by: 
#     - hubot-auth roles
#     - rooms
#     - hubot-auth-middleware environments
#
#   Setting the HUBOT_AUTH_IGNORE_NO_AUTH environment variable to true makes
#   hubot skip listener-middleware checks for any listener without a 
#   listener.options.auth = true. This is useful for multi-bot scenarios where
#   external scripts are in use. 
#
#   Listener options should use the following format:
#     { "id":"someId",
#       "auth":"true",
#       "room":"roomId",
#       "role":"roleName",
#       "env":"authMiddlewareEnv"
#     }
#  
#   If there are no restrictions of a particular type, simply omit the
#   attribute. To limit a command only to a particular room and add no 
#   other limations:
#     { "id":"someId",
#       "room":"powerUserRoomId"
#     }
#
# Dependencies:
#   hubot-auth
#
# Configuration:
#   HUBOT_AUTH_MIDDLEWARE_ENVIRONMENT - defaults to "production"
#   HUBOT_AUTH_MIDDLEWARE_ENVIRONMENT_REPLY - defaults to false
#   HUBOT_AUTH_MIDDLEWARE_IGNORE_NO_AUTH - defaults to false
#
# Commands:
#
logPrefix         = 'auth-middleware'
ignoreNoAuth      = process.env.HUBOT_AUTH_MIDDLEWARE_IGNORE_NO_AUTH or false
authMiddlewareEnv = process.env.HUBOT_AUTH_MIDDLEWARE_ENVIRONMENT or 'production'
environmentReply  = process.env.HUBOT_AUTH_MIDDLEWARE_ENVIRONMENT_REPLY or false

authFail = (context, errorMsg) ->
  context.response.reply errorMsg
  context.response.message.finish()

module.exports = (robot) ->

  robot.listenerMiddleware (context, next, done) ->
    opts    = context.listener.options
    reqUser = context.response.message.user
    reqRoom = context.response.message.room
    reqMsg  = context.response.message.text
    action            = 'Accepting'

    if opts.auth is "true" 
      if opts.env not in [ undefined, authMiddlewareEnv ]
        action = 'Rejecting (env)'
        # By default, don't respond in this case. Env quarantining supports multiple hubots,
        # we want the instance to skip the task, but not clutter the chat room. Env var override available.
        if environmentReply
          authFail context, "#{action} '#{reqUser.name}: #{reqMsg}' -- not executing from this env (hubot instance: #{opts.env})"
        else
          context.response.message.finish()
      if opts.room not in [ undefined, reqRoom ]
        action = 'Rejecting (room)'
        authFail context, "#{action} '#{reqUser.name}: #{reqMsg}' -- use this room: #{opts.room}"
      if opts.role != undefined
        if robot.auth.hasRole(reqUser, opts.role) is false
          action = 'Rejecting (role)'
          authFail context, "#{action} '#{reqUser.name}: #{reqMsg}' -- only allowed by users in role: #{opts.role}"

      # TODO - add a confirmation require w/ timeout? 
      # Spit out a code and the users in a role, and if someone responds with
      # the code write a flag to redis. Periodically check the flag in the timout?

      robot.logger.info "#{logPrefix}: #{action} '#{reqMsg}' request from user: #{reqUser.name} (#{reqUser.id}), room: #{reqRoom}, env: #{authMiddlewareEnv}"

      if action == 'Accepting'
        next()
      else
        done()

    else if ignoreNoAuth
      # Ignore any requests with no listener.options.auth setting
      action = 'Rejecting (ignore_no_auth)'
      context.response.message.finish()

      robot.logger.info "#{logPrefix}: #{action} '#{reqMsg}' request from user: #{reqUser.name} (#{reqUser.id}), room: #{reqRoom}, env: #{authMiddlewareEnv}"

      done()
    else 
      # Auth isn't configured, and the ignore no auth flag isn't set: proceed
      action = 'Accepting (without auth checks)'
      robot.logger.info "#{logPrefix}: #{action} '#{reqMsg}' request from user: #{reqUser.name} (#{reqUser.id}), room: #{reqRoom}, env: #{authMiddlewareEnv}"

      next()

