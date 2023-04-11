function init()
  world.placeDungeon(config.getParameter("dungeonToSpawn"), stagehand.position(), world.dungeonId(stagehand.position()))
  stagehand.die()
end