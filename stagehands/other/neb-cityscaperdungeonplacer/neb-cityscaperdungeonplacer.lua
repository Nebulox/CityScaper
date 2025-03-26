function init()
  world.placeDungeon(config.getParameter("dungeonToSpawn"), stagehand.position(), config.getParameter("id", world.dungeonId(stagehand.position())))
  stagehand.die()
end