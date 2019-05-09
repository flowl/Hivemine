# AgentPlugin.coffee
# safazi 2019

# Injects mineflayer-navigate and our own methods

Mineflayer = undefined
Data = undefined

Navigate = require 'mineflayer-navigate'
Fluture = require 'fluture'
Vec3 = require 'vec3'

Init = (Flayer) ->
	Mineflayer = Flayer
	Navigate = Navigate Flayer
	Inject

# All methods starting with 'hivemine' are intended to be called by the Hivemine handler

Inject = (Agent) ->
	Navigate Agent # Inject Navigate

	if Agent.version
		Data = (require 'minecraft-data') Agent.version
	else
		Agent.once 'inject_allowed', ->
			Data = (require 'minecraft-data') Agent.version


	Agent.toBlock = (BlockOrPoint) -> # General function to resolve blocks or points
		if 'object' == typeof BlockOrPoint
			if BlockOrPoint.hasOwnProperty 'type' # It's a block
				return BlockOrPoint
			else if BlockOrPoint.hasOwnProperty 'x' # It's a point
				return Agent.blockAt BlockOrPoint

	Agent.blockAtOffset = (BlockOrPoint, xOrVec3=0, y=0, z=0) ->
		return if 'object' != typeof BlockOrPoint
		Block = Agent.toBlock BlockOrPoint
		if Block
			if 'object' == typeof xOrVec3 # Vec3 instance
				Agent.blockAt Block.position.plus xOrVec3
			else
				Agent.blockAt Block.position.offset xOrVec3, y, z

	Agent.blockUnder = (Input) ->
		return Agent.blockAtOffset Input, 0, -1, 0

	Agent.blockAbove = (Input) ->
		return Agent.blockAtOffset Input, 0, 1, 0

	Agent.blockIsEmpty = (Input) ->
		Input = Agent.toBlock Input
		return if 'object' != typeof Input
		if Input.hasOwnProperty 'type'
			if Input.boundingBox == 'empty'
				if Input.hardness != undefined
					return true if Input.hardness <= 1 # Avoid portal and water/lava blocks
		false

	Agent.getSurroundingBlocks = (Input, IgnoreAir = true) -> # Get the blocks on all 6 sides.
		Blocks = [	new Vec3  1, 0, 0
					new Vec3  0, 0, 1
					new Vec3  0, 1, 0 ]
		Result = []
		for S in Sides
			Block = Agent.blockAtOffset Input, Side
			Result.push Block  if Block and Block.type != 0 or not IgnoreAir
			Block = Agent.blockAtOffset Input, Side.scaled -1
			Result.push Block if Block and Block.type != 0 or not IgnoreAir
		Result

	Agent.runTask = (Future) -> # Blindly fork a Future - good really only for testing
		onError = (Data) -> console.error 'runTask error:',Data
		onSucceed = (Data) -> console.error 'runTask done:',Data
		Future.fork onError, onSucceed

	Agent.closestPointOutOf = (Points = [], Position = Agent.entity.position) ->
		closest = Number.MAX_SAFE_INTEGER
		point = undefined
		for P in Points
			distance = Position.distanceTo P
			if distance < closest
				distance = closest
				point = P
		point

	Agent.isStandableAir = (Input) -> # See if your feet could theoretically be at Input
		SolidGround = not Agent.blockIsEmpty Agent.blockUnder Input
		FeetSpace = Agent.blockIsEmpty Input
		HeadSpace = Agent.blockIsEmpty Agent.blockAbove Input
		SolidGround and FeetSpace and HeadSpace

	Agent.isStandableGround = (Input) -> # See if you could theoretically stand on top of Input
		Agent.isStandableAir Agent.blockAbove Input

	Agent.findAdjacentBlockAndDirection = (Input) ->
		Input = Agent.toBlock Input
		Adjacent = Agent.getSurroundingBlocks Input
		if Adjacent.length
			return
				block: Adjacent[0]
				direction: Input.position.minus Adjacent[0].position

	Agent.easyPlace = (Input, cb) ->
		Result = Agent.findAdjacentBlockAndDirection Input
		if Result
			Agent.placeBlock Result.block, Result.direction, cb
			return true
		else if cb
			cb 'none'

	Agent.resolveItem = (Input) ->
		Type = typeof Input
		if Type == 'object' # Could already be an Item
			return Input if Input.hasOwnProperty 'type'
		else if Type == 'number' # ID
			return Data.items[Input]
		else if Type == 'string' # Name or ID
			N = parseInt Input
			if N != 0 and not N # Name
				return Data.itemsByName[Input]
			else # ID
				return Data.items[N]

	Agent.easyEquip = (ResolvesToItem, dest = "hand", cb) ->
		Item = Agent.resolveItem ResolvesToItem
		Agent.equip Item.type, dest, cb if Item

	Agent.changeRole = (NewRole) -> Agent.Hivemine.requestRoleChange Agent, NewRole if Agent.Hivemine
	
	Agent.hivemineAssignedRole = (Role) -> Role.onEnter Agent
	Agent.hivemineSetHivemine = (Hivemine) -> Agent.Hivemine = Hivemine

module.exports = Init