//moves:[{type:'F',from:18,to:27},{"type":"FJ","moves":[{"from":11,"jump":20,"to":29},{"from":29,"jump":38,"to":47},{"from":47,"jump":54,"to":61}]}]
UNWIND {moves} AS m
WITH m
MATCH (startTile:Tile{id:head(m.moves).from})
MATCH (endTile:Tile{id:last(m.moves).to})
// Set base weight
WITH m,startTile,endTile, (CASE m.type WHEN 'F' THEN 1 WHEN 'FJ' THEN 2*length(m.moves) ELSE 0 END) AS weight, 
	EXISTS((:Game{id:{gameId}})--(:Counter:Visible:Crowned)--(:Tile{id:head(m.moves).from})) AS crowned

//Add .25 if start is in danger
WITH m,startTile,endTile, weight, crowned,
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
WITH m,startTile,endTile, crowned, 
	(CASE WHEN (dangerFrom AND crowned) THEN weight+0.5
		  WHEN (dangerFrom AND NOT crowned) THEN weight+0.25
		  ELSE weight END) AS weight,dangerFrom

//Results in piece being crowned
WITH m,startTile,endTile, crowned, weight,dangerFrom,
(NOT crowned) 
AND 
REDUCE(c=false, n IN m.moves | c=c AND (n.to IN [57,59,61,63])) AS crowning
		
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
		  ELSE weight END) AS weight,dangerFrom, dangerTo,crowning
				
WITH {type:m.type, moves:m.moves,weight:weight} AS move,startTile,endTile,dangerFrom,crowned,dangerTo,crowning
RETURN move,startTile,endTile,dangerFrom,crowned,dangerTo,crowning