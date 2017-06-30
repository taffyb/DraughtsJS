var statement="MATCH (Game{id:'&gameId&'})--(c:Counter:&playerColour&)--(:Tile)-[:&playerDirection&]-";


function prepareStatment(statement, tokens){
	var s = statement;
	Object.keys(tokens).forEach(function(key,i){
		console.log("key:"+key+" value:"+tokens[key]);
		s = s.replace("&"+key+"&",tokens[key]);
	});
	return s;
}



console.log(prepareStatment(statement,{playerColour:'Black',playerDirection:'FORWARD',gameId:'2'}));