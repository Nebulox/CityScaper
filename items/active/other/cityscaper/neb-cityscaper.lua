require "/scripts/vec2.lua"

function init()
  self.dungeon = config.getParameter("dungeon", "avianairship")
  self.offsetY = root.imageSize(config.getParameter("dungeonPreview"))[2] * 0.125
  activeItem.setScriptedAnimationParameter("neb-dungeonPreview", config.getParameter("dungeonPreview"))
  
  self.lastFireMode = "none"

  updateAim()
end

function update(dt, fireMode, shiftHeld)
  updateAim()

  if fireMode == "primary" and self.lastFireMode ~= "primary" then
	local pos = activeItem.ownerAimPosition()
	pos[2] = pos[2] + self.offsetY
	if not world.isTileProtected(pos) then
	  world.spawnStagehand(pos, "neb-cityscaperdungeonplacer", { dungeonToSpawn = self.dungeon, id = player.id() })
	  item.consume(1)
	end
  elseif fireMode == "alt" and self.lastFireMode ~= "alt" then    
    activeItem.interact("ScriptPane", "/interface/scripted/cityscaper/neb-cityscaper.config")
  end
  self.lastFireMode = fireMode
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  activeItem.setArmAngle(self.aimAngle)
  activeItem.setFacingDirection(self.aimDirection)
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, self.aimAngle + sb.nrand(config.getParameter("inaccuracy", 0), 0))
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end

function holdingItem()
  return true
end

function recoil()
  return false
end

function outsideOfHand()
  return false
end
