// By Nirav Bhatt.
// Import the opentok library from the subdirectory
// Replace XXXXXXX with API Key from tokbox.com
// Replace YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY with secret from tokbox.com.

var opentok = require('cloud/opentok/opentok.js').createOpenTokSDK('XXXXXXX', 'YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY');  
 
// Every ActiveSessions object should "own" an OpenTok Session
Parse.Cloud.beforeSave("ActiveSessions", function(request, response)
{
    var activeSession = request.object;
  
    // If this ActiveSessions already has a sessionId, we are done
    if (activeSession.get("sessionID")) { response.success(); return; }
  
    // Otherwise, we create a Session now...
    opentok.createSession(function(err, sessionId)
    {
    // Handle any errors
        if (err)
        {
            response.error("could not create opentok session for activeSession: " + activeSession.id);
            return;
        }
        // ... and now save the sessionId in the ActiveSessions object
        activeSession.set("sessionID", sessionId);     
         
        //now, generate the token please...
        var publisherToken = opentok.generateToken(sessionId, { "role" : opentok.ROLE.PUBLISHER });
        if (publisherToken) 
        {
        }
        else
        {
            response.error("could not create publisher token for activeSession: " + activeSession.id);
            return;
        }
         
        var subscriberToken = opentok.generateToken(sessionId, { "role" : opentok.ROLE.SUBSCRIBER });
        if (subscriberToken) 
        {
        }
        else
        {
            response.error("could not create publisher token for activeSession: " + activeSession.id);
            return;
        }
        // ... and now save the sessionId in the ActiveSessions object
        activeSession.set("publisherToken", publisherToken);
        activeSession.set("subscriberToken", subscriberToken);     
        response.success();
});
});
  
  
// This function can be called by any user who wants to connect to a ActiveSessions and a Token with the
// corresponding `role` will be generated. (Publisher for the ActiveSessions owner, Subscriber for anyone else)
Parse.Cloud.define("getActiveSessionsToken", function(request, response)
{
    // Retrieve the ActiveSessions object for which the token is being requested
    var activeSessionId = request.params.activeSession;
    if (!activeSessionId) response.error("you must provide a activeSession object id");
    var activeSessionQuery = new Parse.Query("ActiveSessions");
     
    activeSessionQuery.get(activeSessionId,
    {
        // When the ActiveSessions object is found...
        success: function(activeSession)
        {
            // Get the appropriate role according to the user who is calling this function
            var role = roleForUser(activeSession, request.user);
            // Create a Token
            var token = opentok.generateToken(activeSession.get("sessionID"), { "role" : role });
            // Return the token as long as it exists
            if (token)
            {
                response.success(token);
                // Handle errors
            }
            else
            {
                response.error("could not generate token for activeSession id: " + activeSessionId + " for role: " + role);
            }
        },
        // When the ActiveSessions object is not found, respond with error
        error: function(activeSession, error)
        {
            response.error("cannot find activeSession with id: " + activeSessionId);
        }
    });
});
  
// Helper function to figure out the OpenTok role a user should get based on the Boradcast object
var roleForUser = function(activeSession, user)
{
    // A ActiveSessions owner gets a Publisher token
    if (activeSession.get("callerID").id === user.id)
    {
        return opentok.ROLE.PUBLISHER;
        // Anyone else gets a Subscriber token
    }
    else
    {
        return opentok.ROLE.SUBSCRIBER;
    }
};
