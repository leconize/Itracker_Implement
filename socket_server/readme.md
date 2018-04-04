# Requirement for project
- the project will be able to receive data from mobile phones by socket server.
- The socket server will be TCP server if it's possible
- There will be two type of data coming from the phone.The first type is images of web page user are watching and the second is the position of eye gaze of the user.
- the format of the image data will be jpeg because it will cause lesser data space and improve load time.
- database of this project is PostgreSQL.

# Socket Expected Behavior
- After connection success. Will request for the image of the webpage.
- after getting the image of the webpage the server will save data in the filesystem in folder ./img and save path to the database.database will generate ID with auto increment and send back to the socket server.
- socket server would reply id of the image in the database to mobile if all of the operations succeeded.
- after initialization complete mobile will send gaze point(x, y) along with the id of the image to ensure that gaze point.