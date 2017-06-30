//PARAMS: gameId
MATCH (:Game{id:{gameId}})-[:HAS]->(c:Counter:Black:Visible)

//Forward Moves
MATCH (:Game{id:{gameId}})-[:HAS]->(c:Counter:Black:Visible)-[:OCCUPIES]->(from:Tile)-[d:FORWARD]->(to:Tile) 
WITH collect({type:'F',moves[{from:from.id,to:to.id}]}) AS m

//Back moves
MATCH (:Game{id:{gameId}})-[:HAS]->(c:Counter:Black:Visible)-[:OCCUPIES]->(from:Tile)-[d:BACKWARD]->(to:Tile) 
WITH m+collect({type:'B',moves:[{from:from.id,to:to.id}]}) AS m
UNWIND m AS move
WITH move
RETURN move.type,move.from, move.jump, move.to	