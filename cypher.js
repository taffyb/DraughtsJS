var Promise = require('promise');
var fs = require('fs');

/**
 * cypherName 	: String - Name of file containing cypher statement
 * cypherParams	: Map - Paramenters to be used in the cypher statement
 * tokens		: Map - values to be used for string substitution before statement is executed
 * action 		: Function - Function to handle the result returned from neo4j
 * neo4jSession : Neo4j Session used to run the statement
 */
exports.load= function(cypherName, cypherParams, tokens,  action, neo4jSession){
		var filename = "./cypher/"+cypherName+".cypher";
		var session = neo4jSession;

		fs.readFile(filename, (err, data)=>  {
		  if (err){ throw err;}
		  var statement = data.toString();
		  statement = prepareStatment(statement,tokens);
		  session
			.run(statement,cypherParams)	
			.then(action)
			.catch(function(err){
				console.log(err);
			});
		});

		console.log("finished reading file");
	};
	
	function prepareStatment(statement, tokens){
		var s = statement;
		Object.keys(tokens).forEach(function(key,i){
			console.log("key:"+key+" value:"+tokens[key]);
			while(s.search("&"+key+"&")>0){
				s = s.replace("&"+key+"&",tokens[key]);
			}
		});
//		console.log(s);
		return s;
	}

