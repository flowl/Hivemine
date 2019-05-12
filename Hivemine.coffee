# Hivemine.coffee
# Oversees all agents

###
	
	General ideas:
		Hivemine will store a server-by-server flatfile with important information such as locations, items, tasks, etc.
		Agents will be able to:
			- Query this flatfile
			- Request items and tasks from other Agents

###

EventEmitter = require 'events'

class ServerInformation
	constructor: (@Host, @Port = 25565, @Name) ->
		Parts = @Host.split ':'
		if Parts.length
			@Port = parseInt Parts[1]	# Server port
			@Host = Parts[0]			# Server host
			@Name = @Host if not @Name 	# Name for flatfile DB

class Hivemine extends EventEmitter # thanks wvffle!
	constructor: ->
		super()
		@Agents = []

	inquire: (Key) ->
		# Query the flatfile for a certain key
		# Would return a forked future or something.

	addAgent: (Agent) ->
		if -1 == @Agents.indexOf Agent
			Agent.hivemineSetHivemine @
			@Agents.push Agent

	findFreeAgent: ->
		# TODO: take role into consideration
		for Agent in @Agents
			return Agent if Agent.Free

	setServer: (@ServerInformation) ->
	setAgentCount: (@AgentCount = 1) ->

	fetchRole: (Name) -> # Todo: Read ./roles/ and get the role
	assignRole: (Agent, Role) -> Agent.hivemineAssignedRole Role
	requestRoleChange: (Agent, NewRole) ->
		return if Agent.Role == NewRole
		if Agent.Role
			# Quit that role
			Agent.Role = undefined

		NewRole = @fetchRole NewRole
		@assignRole Agent, NewRole if NewRole

###
	requestItem
###