var neo4j = require('neo4j-driver').v1;
var properties = require('./properties');

exports.getSession= function(){

	var driver = neo4j.driver("bolt://"+properties.props.neo4j.host,neo4j.auth.basic(properties.props.neo4j.user, properties.props.neo4j.password));
	var session = driver.session();
	
	return session;
};
exports.toNumber= function(number){return neo4j.integer.toNumber(number);};