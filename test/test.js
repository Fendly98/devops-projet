request = require("request");
should = require("should");


describe('Application', function() {

it('Checks GET / of test application', function(done) {


request.get('http://localhost:3000', function(err,response) {

response.statusCode.should.equal(200);
response.body.should.equal('Hello World!');
response.body.should.not.have.property('error')
done();

})

});

});