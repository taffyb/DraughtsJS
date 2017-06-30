MATCH (game:Game{id:toString({gameId})})-[:HAS]->(old:Counter)-[:OCCUPIES]-(:Tile{id:{fromId}})
MATCH (to:Tile{id:{toId}})
MATCH (Tile{id:{jumpId}})<-[:OCCUPIES]-(jump:Counter:Visible)
CREATE (new:Counter{id:apoc.create.uuid()})
SET new.game=game.id, new.player=old.player
WITH game,old,new,to,jump
MERGE (game)-[:HAS]->(new)
MERGE (new)-[:OCCUPIES]->(to)
WITH old,new,jump
CALL apoc.create.addLabels(new,[old.player,'Visible']) YIELD node
WITH old,new,jump
REMOVE old:Visible
REMOVE jump:Visible
MERGE (old)-[m:MOVED_TO]->(new)
SET m.id={moveId}