var cypher = require('./cypher');
var neo4j = require('./neo4j');
var debug = false;

var ADD_WEIGHTS = "AddWeightsToMoves";
var FIND_JUMP_MOVES_WITH_WEIGHTS = "FindWeightedSimpleJumpMoves";
var FIND_JUMP_MOVES1 = "FindSimpleJumpMoves";

function compareMoves(m1,m2){
	for(var i=0;i<m1.length;i++){
		if(m1[i].from!==m2[i].from){
			return false;
		}
	}
	return true;
}

function filterMoves(moves){
	var tempMoves=[];

	moves.forEach((move,i)=>{
		var last = tempMoves.slice(-1)[0];
		if(tempMoves.length===0){
			if(debug){console.log("tempMoves Empty\n");}
			tempMoves.push(move);
		}else{			
			if(move.moves.length>last.moves.length){
				if(debug){console.log("move.moves.length ("+move.moves.length+">"+last.moves.length+") last.moves.length\n");}
				tempMoves.push(move);
			}else{
				var tempMove=[];
				for(var i=0;i<move.moves.length;i++){
					tempMove.push(last.moves[i]);
				}
				if(!compareMoves(move.moves,tempMove)){
					tempMoves.push(move);
				}
			}
		}
	});
	return tempMoves;	
}

function runTest(func){
	var start = new Date().getTime();
	func();
	console.log(func.name +"["+(new Date().getTime() -start)+"ms]");
}

cypher.load(FIND_JUMP_MOVES1,{gameId:'2'},{opponentColour:'White',
										   playerDirection:'FORWARD',
										   playerColour:'Black'},function(result){
	var moves=[];
	
	result.records.forEach(function(record){
		var moveArray=[];
		record.get("move").moves.forEach(function(move){
			var m ={
					'from':neo4j.toNumber(move.start),
					'jump':neo4j.toNumber(move.jump),
					'to':neo4j.toNumber(move.to)
					};
			moveArray.push(m);
		});
							
		moves.push({'type':'FJ','moves':moveArray});
		moveArray=[];
	});	

	console.log("Unfiltered Moves: ["+moves.length+"]\n");
	moves=filterMoves(moves);
	console.log("Filtered Moves: ["+moves.length+"]\n");
	console.log("Filtered Moves "+JSON.stringify(moves)+"\n");
},neo4j.getSession());





