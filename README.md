# SaushEngine2

An all new and improved SaushEngine! _This is work in progress, please do not use yet!_

## Features


## Install


## How to use



## Spider algorithm

1. Read url from queue (assume - URLs in queue are clean)
2. Find page or create a new one, based on the url
3. Extract words from the url, put into words array
4. Extract keywords from the url, put into the front of the words array
5. For every word in the words array, 
    - Find word or create a new one
    - Create a location with a position, which is the index of the array
6. Extract links from the url
7. For every link in the url, 
    - If it is a relative url, add the base url
    - If authentication is required, add in user name and password (TODO)  
    - Add it into the queue if under n messages in the queue


