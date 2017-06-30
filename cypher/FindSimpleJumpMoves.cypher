MATCH p=(start:Tile)-[:&playerDirection&*2..8]->(t:Tile)
WHERE (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:&playerColour&)-[:OCCUPIES]->(start)	
WITH p,start,nodes(p)[1] as jump,nodes(p)[2] as to,nodes(p)[3] as jump2,nodes(p)[4] as to2, nodes(p)[5] as jump3,nodes(p)[6] as to3
WITH p,CASE
	WHEN //Look for 3 Jumps
      //1
      (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:&opponentColour&)-[:OCCUPIES]->(jump)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to)))
      AND (start.column+2=to.column OR start.column-2=to.column)
      //2
  	  AND (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:&opponentColour&)-[:OCCUPIES]->(jump2)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to2)))
      AND (to.column+2=to2.column OR to.column-2=to2.column)
      //3
	  AND (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:&opponentColour&)-[:OCCUPIES]->(jump3)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to3)))
      AND (to2.column+2=to3.column OR to2.column-2=to3.column)
    THEN {type:'FJ',moves:[{start:start.id,jump:jump.id,to:to.id},
          {start:to.id,jump:jump2.id,to:to2.id},
          {start:to2.id,jump:jump3.id,to:to3.id}]}
	WHEN //Look for 2 jumps
      //1
      (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:&opponentColour&)-[:OCCUPIES]->(jump)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to)))
      AND (start.column+2=to.column OR start.column-2=to.column)
      //2
	  AND (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:&opponentColour&)-[:OCCUPIES]->(jump2)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to2)))
      AND (to.column+2=to2.column OR to.column-2=to2.column)
    THEN {type:'FJ',moves:[{start:start.id,jump:jump.id,to:to.id},
          {start:to.id,jump:jump2.id,to:to2.id}]}
    WHEN //Look for 1 jump 
      //1
      (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:&opponentColour&)-[:OCCUPIES]->(jump)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to)))
      AND (start.column+2=to.column OR start.column-2=to.column)
    THEN {type:'FJ',moves:[{start:start.id,jump:jump.id,to:to.id}]}
    END AS m
WITH m
WITH distinct m  as dm
WITH collect(dm) as moves
WITH REDUCE(out=[], i IN range(length(moves)-1,0,-1) | out+[moves[i]]) AS moves
UNWIND moves as move
WITH move
WHERE move.moves IS NOT NULL
RETURN  move 