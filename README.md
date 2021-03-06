Hubot-auth-middleware adds listener middleware for restricting command access. Rooms, roles (hubot-auth), and environments are supported as command restriction concepts.

The core implementation uses listener options attributes that are processed in the auth-middleware's listenerMiddlware. You can create access-controled commands using formats like:

````
  listenerOptions = {"id":"makeSandwich","auth":"true","roles":"sudoers"}

  robot.hear /make me a sandwich/, listenerOptions, (msg) ->
    msg.send "you are a sandwich"
````

If the request comes from a user who does not have the `sudoers` role, an error notification is logged and replied.

The various access control types can be combined as necessary. The `roles` and `rooms` values can be strings or arrays, so these all work:
````
  listenerOptionsX = {"id":"secretStuff","auth":"true","roles":["sudoers","admin","wheel"],"rooms":"#situation"}
  ...
  listenerOptionsY = {"id":"reallySecretStuff","auth":"true","roles":"chiefs","rooms":["#panic","#emergency"]}
  ...
  listenerOptionsZ = {"id":"justForClarity","auth":"true","roles":["admin"],"rooms":"#panic"}
````

## Installation

Add the hubot-auth-middleware package to hubot/package.json dependencies and hubot/external-scripts.json. hubot-auth-middleware requires the hubot-auth script to function properly.


## Configuration

Hubot-auth-middleware supports environment variables:

  - HUBOT_AUTH_MIDDLEWARE_ENVIRONMENT - sets an environment that hubot-auth-middleware uses to confirm env-specific controls, defaults to 'production'
  - HUBOT_AUTH_MIDDLEWARE_IGNORE_NO_AUTH - if true the given hubot instance will ignore any listeners where the listener.option.auth attribute is not "true"
  - HUBOT_AUTH_MIDDLEWARE_ENVIRONMENT_REPLY - if true the instance will send a response message for environment rejections


## Quick Start

You will need a recent Hubot version (supporting middleware). If middleware support is available, adding access controls is as easy as passing explicit listener.options in your listeners:

````
...
+    listenerOptions = {"id":"someCommand","auth":"true","roles":"admins"}
-    robot.hear /some command/, (msg) ->
+    robot.hear /some command/, listenerOptions, (msg) ->  
       # does some stuff
...
````

### Environments

In some organizations multiple chatbots serving multiple environments (data centers, vpc, etc.) is convenient. Rather than having entirely custom chatbots for every environment, auth-middleware lets you declare that a particular chatbot should ignore any requests without auth-middleware configuration (HUBOT_AUTH_MIDDLEWARE_IGNORE_NO_AUTH=true environment variable). With this configuration, you can have a 'production' hubot and a 'stage1' hubot both running and listening in the same room, but only respond to a particular request from one bot.

````
  listenerOptions = {"id":"restartDatabase","auth":"true","env":"stage1"}

  # Never in prod!!!
  robot.hear /restart (db|database)/, listenerOptions, (msg) ->
    # Errors if env is non-stage1
    #
    # db restart logic...
    msg.send "database restarted"
````

### Roles

Custom roles support basic access control groups. If deploy, infrastructure, or other commands must be limited to particular users, assign all those users a role and declare that role as required for a given command listener.

````
  listenerOptions = {"id":"deleteUser","auth":"true","roles":"mgmt"}
  
  robot.hear /userDelete ([\w]+)/, listenerOptions, (msg) ->
    # Errors if request.user is not in role mgmt
    #
    # userDelete logic...
    msg.send "Deleted user msg.match[1]"
````

### Rooms

Room quarantines are helpful for lots of circumstances. Using auth-middleware room controls lets multiple bots listen wherever they want, but only respond to room-specific requests. For some bot-user/adapter configurations this is much easier than per-room quarantining at the adapter/user level.

````
  listenerOptions = {"id":"youtubeSearches","auth":"true","rooms":"videosRoom"}

  robot.hear /youtube me (.*)/, listenerOptions, (msg) ->
    # Errors if the request is anywhere other than the 'videosRoom'
    #
    # Youtube video search...
    msg.send videolink
````

### Audits and Logging

hubot-auth-middleware writes event details to INFO logs for audit needs. Messages include the following:
 - 'auth-middleware' tag
 - action (accepting|rejecting)
 - action reason (valid auth, wrong room, wrong environment, etc.)
 - request command
 - user and user id making the request
 - room where the request was made
 - environment of the given Hubot instance

#### Example log:

These are the log outputs from the test suite. Note that I removed the timestamps for human-readability and to focus on the actual log message. Also, by default these are not displayed during testing (HUBOT_LOG_LEVEL='warning').

````
INFO auth-middleware: Accepting (without auth checks) 'amTest no options' request from user: adminUser (1), room: #test, env: x
INFO auth-middleware: Accepting (without auth checks) 'amTest strange options' request from user: adminUser (1), room: #test, env: x
INFO auth-middleware: Rejecting (env) 'amTest reject environment' request from user: adminUser (1), room: #test, env: x
INFO auth-middleware: Rejecting (room) 'amTest reject room' request from user: adminUser (1), room: #test, env: x
INFO auth-middleware: Rejecting (role) 'amTest reject role' request from user: adminUser (1), room: #test, env: x
INFO auth-middleware: Accepting (valid auth) 'amTest allow environment' request from user: adminUser (1), room: #test, env: x
INFO auth-middleware: Accepting (valid auth) 'amTest allow room' request from user: otherUser (2), room: #x, env: x
INFO auth-middleware: Accepting (valid auth) 'amTest allow role' request from user: adminUser (1), room: #test, env: x
````

## Testing

Test utilities are listed as devDependencies, and [nvm](https://github.com/creationix/nvm) is in place for nodejs version management. If you want to run tests or make updates, use:

````
nvm use
npm install
npm test
````

