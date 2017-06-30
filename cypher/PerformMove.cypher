MATCH (game:Game{id:toString({gameId})})-[:HAS]->(old:Counter)-[:OCCUPIES]-(:Tile{id:{fromId}}) 
MATCH (to:Tile{id:{toId}}) 
CREATE (new:Counter{id:apoc.create.uuid()}) 
SET new.game=game.id, new.player=old.player 
WITH game,old,new,to
MERGE (game)-[:HAS]->(new) 
MERGE (new)-[:OCCUPIES]->(to) 
WITH old,new 
CALL apoc.create.addLabels(new,[old.player]) YIELD node 
WITH old,new 
CALL apoc.create.addLabels(new,['Visible']) YIELD node 
REMOVE old:Visible 
MERGE (old)-[m:MOVED_TO]->(new) 
SET m.id={moveId}