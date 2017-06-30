/**
 * http://usejsdoc.org/
 */
var http = require('http');
http.createServer(function handler(req, res) {
	
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('Hello World\n');
}).listen(3000);
console.log('Server running at http://localhost:3000');