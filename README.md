# SaushEngine

SaushEngine is a simple, customizable search engine that allows you to crawl through anything and anywhere for data. You can use it to crawl an intranet or a file server for documents, spreadsheets and slides or even your computer.

_This is work in progress, please do not use yet!_

## Features


## Install


## How to use


## Dependencies

These are the basic components it need:

* JRuby
* RabbitMQ
* Postgres

To find a list of Ruby libraries it needs, please view the Gemfile.

## How it works

The search engine has two parts:

1. The Spider - goes out to collect data for the search engine
2. The Digger - allows your user to search 


## Spider

### Spider algorithm

This is the algorithm used by the Spider.

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


## Digger