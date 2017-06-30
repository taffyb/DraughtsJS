MATCH p=(start:Tile)-[:FORWARD*2..8]->(t:Tile)
WHERE (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:Black)-[:OCCUPIES]->(start)	
WITH p,start,nodes(p)[1] as jump,nodes(p)[2] as to,nodes(p)[3] as jump2,nodes(p)[4] as to2, nodes(p)[5] as jump3,nodes(p)[6] as to3
WITH p,CASE
	WHEN //Look for 3 Jumps
      //1
      (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:White)-[:OCCUPIES]->(jump)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to)))
      AND (start.column+2=to.column OR start.column-2=to.column)
      //2
  	  AND (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:White)-[:OCCUPIES]->(jump2)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to2)))
      AND (to.column+2=to2.column OR to.column-2=to2.column)
      //3
	  AND (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:White)-[:OCCUPIES]->(jump3)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to3)))
      AND (to2.column+2=to3.column OR to2.column-2=to3.column)
    THEN {type:'FJ',moves:[{start:start.id,jump:jump.id,to:to.id},
          {start:to.id,jump:jump2.id,to:to2.id},
          {start:to2.id,jump:jump3.id,to:to3.id}]}
	WHEN //Look for 2 jumps
      //1
      (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:White)-[:OCCUPIES]->(jump)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to)))
      AND (start.column+2=to.column OR start.column-2=to.column)
      //2
	  AND (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:White)-[:OCCUPIES]->(jump2)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to2)))
      AND (to.column+2=to2.column OR to.column-2=to2.column)
    THEN {type:'FJ',moves:[{start:start.id,jump:jump.id,to:to.id},
          {start:to.id,jump:jump2.id,to:to2.id}]}
    WHEN //Look for 1 jump 
      (:Game{id:{gameId}})-[:HAS]->(:Counter:Visible:White)-[:OCCUPIES]->(jump)
      AND (NOT EXISTS ((:Game{id:{gameId}})-[:HAS]->(:Counter:Visible)-[:OCCUPIES]->(to)))
      AND (start.column+2=to.column OR start.column-2=to.column)
    THEN {type:'FJ',moves:[{start:start.id,jump:jump.id,to:to.id}]}
    END AS m
WITH m
WITH distinct m  as dm
ORDER BY m.type,coalesce(m.moves[0].start,65),coalesce(m.moves[0].to,65), coalesce(m.moves[1].start,65),coalesce(m.moves[1].to,65), coalesce(m.moves[2].start,65), coalesce(m.moves[2].to,65)
WITH collect(dm) as moves

//Filter to single moves
WITH REDUCE(out=[], a IN moves |  out+(CASE 
			WHEN (length(out)=0) OR 
				 (length(last(out).moves)<length(a.moves)) OR
				 ( (length(a.moves)>=1) AND (NOT (a.moves = REDUCE(o=[], i IN range(0,length(a.moves)-1)  | o+last(out).moves[i]))) )
				THEN [a] 
			ELSE []
		  END)
     ) AS moves
     
UNWIND moves as m
WITH m
MATCH (startTile:Tile{id:head(m.moves).start})
MATCH (endTile:Tile{id:last(m.moves).to})
WITH m,startTile,endTile,
	CASE {playerDirection} WHEN 'FORWARD' THEN [57,59,61,63] ELSE [2,4,6,8] END AS lastRow, 
	CASE {playerDirection} WHEN 'BACKWARD' THEN [2,4,6,8] ELSE [57,59,61,63] END AS firstRow
// Set base weight
WITH m,startTile,endTile,lastRow,firstRow, (CASE m.type WHEN 'F' THEN 1 WHEN 'FJ' THEN 2*length(m.moves) ELSE 0 END) AS weight, 
	EXISTS((:Game{id:{gameId}})--(:Counter:Visible:Crowned)--(:Tile{id:head(m.moves).from})) AS crowned

//Add .25 if start is in danger
WITH m,startTile,endTile, weight, crowned,lastRow,firstRow, 
	CASE WHEN ( ( 
				  EXISTS((:Game{id:{gameId}})--(:Counter:White:Visible)--(:Tile{column:startTile.column+1,row:startTile.row+1}))
					AND
				  NOT EXISTS((:Game{id:{gameId}})--(:Counter:Visible)--(:Tile{column:startTile.column-1,row:startTile.row-1}))
				) OR
				( 
				  EXISTS((:Game{id:{gameId}})--(:Counter:White:Visible)--(:Tile{column:startTile.column-1,row:startTile.row+1}))
					AND
				  NOT EXISTS((:Game{id:{gameId}})--(:Counter:Visible)--(:Tile{column:startTile.column+1,row:startTile.row-1}))
				)
			  )	THEN true
		 ELSE false END AS dangerFrom
WITH m,startTile,endTile, crowned, lastRow,firstRow, 
	(CASE WHEN (dangerFrom AND crowned) THEN weight+0.5
		  WHEN (dangerFrom AND NOT crowned) THEN weight+0.25
		  ELSE weight END) AS weight,dangerFrom

//Results in piece being crowned
WITH m,startTile,endTile, crowned, weight,dangerFrom,lastRow,firstRow, 
(NOT crowned) 
AND 
	CASE {playerDirection} WHEN 'FORWARD' THEN REDUCE(c=false, n IN m.moves | c=c AND (n.to IN lastRow))
						   ELSE REDUCE(c=false, n IN m.moves | c=c AND (n.to IN firstRow)) END AS crowning
		
//reduce 0.5 if ends in danger
WITH m,startTile,endTile, weight, crowned,crowning,dangerFrom,
	CASE WHEN ( ( 
				  EXISTS((:Game{id:{gameId}})--(:Counter:White:Visible)--(:Tile{column:endTile.column+1,row:endTile.row+1}))
					AND
				  (NOT EXISTS((:Game{id:{gameId}})--(:Counter:Visible)--(:Tile{column:endTile.column-1,row:endTile.row-1}))
				  	OR endTile.column-1 = startTile.column)
				) OR
				( 
				  EXISTS((:Game{id:{gameId}})--(:Counter:White:Visible)--(:Tile{column:endTile.column-1,row:endTile.row+1}))
					AND
				  NOT EXISTS((:Game{id:{gameId}})--(:Counter:Visible)--(:Tile{column:endTile.column+1,row:endTile.row-1}))
				  	OR endTile.column+1 = startTile.column
				)
			  )	THEN true
		 ELSE false END AS dangerTo
WITH m,startTile,endTile, crowned,
	(CASE WHEN (dangerTo AND (crowned or crowning)) THEN weight-0.75
		  WHEN (dangerTo AND NOT (crowned or crowning)) THEN weight-0.5
		  ELSE weight END) AS weight
				
WITH {type:m.type, moves:m.moves,weight:weight} AS move
RETURN  move 