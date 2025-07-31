public with sharing class JoobleJSONCalloutMockGenerator implements HttpCalloutMock {
    
    public static String DUMMY_JSON_USER_PAYLOAD = '{"totalCount":1,"jobs":[{"title":"TESTSalesforce Developer (Hybrid)","location":"Des Moines, IA","snippet":"&nbsp;...functional teams, your work will focus on maximizing the value of our <b>Salesforce </b>platform to support our sales and service teams’ daily...&nbsp;&nbsp;...efficient code with proper documentation and automated testing \\n <b>Develop</b>custom solutions utilizing Salesforce platform capabilities...&nbsp;","salary":"$71k - $101k","source":"icims.com","type":"Full-time","link":"https://jooble.org/desc/-6953195744302009814?ckey=Salesforce+developer&rgn=16682&pos=1&groupId=40906&elckey=-1611558286448558113&p=1&aq=-2828607149973070666&cid=5537&jobAge=1532&brelb=100&bscr=89.929436&scr=89.929436","company":"Principal Financial Group","updated":"2025-05-28T00:00:00.0000000","id":-6953195744302009814}]}';

	public HTTPResponse respond(HTTPRequest req) {
		// Create a fake response
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');

		// Check if the request is a POST request
		if (req.getMethod() == 'POST') {
			// Return a success response for the POST request
			res.setBody(DUMMY_JSON_USER_PAYLOAD);
		} else {
			// Return the dummy user details for the GET request
			res.setBody(DUMMY_JSON_USER_PAYLOAD);
		}
		res.setStatusCode(200);
		return res;
	}

}