1. Follow instructions on https://www.parse.com/docs/cloud_code_guide to install parse command line tool (CLI) on your mac or windows box.

2. Create a directory called Projects/LiveSessions on your favorite path and make sure that parse.exe is invokable from there (ie either in same directory or in path variable)

3. Go to command prompt and execute: parse new

This will ask for your parse.com email and password. Enter them.
Upon successful authentication, it will ask you to select the app you want to deploy cloud code for.
Select the index number of LiveSessions app.

Once above is done, there will be a folder structure on your Projects/LiveSessions path, like this:

# Directory layout:
#
# Projects/LiveSessions 
# 		|- parse/
# 			|- cloud/
# 				|- main.js <----- TO BE EDITED BY iOS Developer
#				|- opentok/ <----- opentok includes go here
# 					|- opentok.js
# 					|- ...
# 			|- config/
# 				|- global.json

4. Next, edit main.js in your favourite text editor. 
For LiveSessions to work, all you need to do is overwrite the main.js with the one from "LiveSessions\Parse-cloud-code\cloud\" folder and enter your own Tokbox API key as well as Tokbox secret in place of placeholders XXXXXXX and YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY.

5. Save and exit main.js. 
6. On command prompt, execute: parse deploy.

Above will upload cloud code into your Parse.com LiveSessions app. Refresh  your parse.com through your browser and you should see version v1 uploaded (v2, v3 onwards if it is not the first time)