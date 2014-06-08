# SaushEngine

SaushEngine is a simple, customizable search engine that allows you to crawl through anything and anywhere for data. You can use it to crawl an intranet or a file server for documents, spreadsheets and slides or even your computer.

_This is work in progress, please do not use yet!_

## How it works

The search engine has two parts:

1. The Spider - goes out to collect data for the search engine
2. The Digger - allows your user to search through the index


## Features

The following are features found in SaushEngine:

1. Multiple parallel crawlers for creating the search index
2. Crawlers can process multiple document formats including HTML, Microsoft Word, Adobe PDF and many others
3. Crawlers can be customized to search specific domains only
4. Crawlers can search through NTLM protected sites (Sharepoint etc)
5. Web-based crawler management interface
6. Search can be specific to mime-types

## Install

To install SaushEngine, do the following steps in sequence:

1. Install Ruby (preferably use [rbenv](https://github.com/sstephenson/rbenv))
2. Install [Postgres (9.3)](http://www.postgresql.org/)
3. Install [RabbitMQ](https://www.rabbitmq.com/)


## Dependencies

These are the basic components it need:

* [JRuby](http://www.jruby.org) - Ruby implementation on top of the Java Virtual Machine
* [RabbitMQ](https://www.rabbitmq.com/) - an easy to use and robust messaging system
* [Postgres](http://www.postgresql.org/) - A powerful open source relational database

To find a list of Ruby libraries it needs, please view the Gemfile.


## Spider

The SaushEngine spider crawls through the search space for documents, which it then adds to the search index (database). 

### Design

To run multiple spiders at the same time, SaushEngine uses Celluloid to run parallel threads. Each thread runs independently and acts as a worker that consumes a queue (using RabbitMQ) of document URLs. As each spider consumes a URL, it will process the document and generates URLs which are published into the same queue.

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
    - If authentication is required, add in user name and password
    - Add it into the queue if under n messages in the queue

### Analysing the documents retrieved

SaushEngine's spider analyses the documents it crawls depending on the type of document:

1. HTML - [Nokogiri](http://nokogiri.org/), using customized logic to process a HTML file
2. Any other types - [Apache Tika](http://tika.apache.org/) which extracts text from many different file formats. Supported [file formats](http://tika.apache.org/1.5/formats.html) can be found [here](http://tika.apache.org/1.5/formats.html)


## Digger


## Customizing SaushEngine

SaushEngine is a highly customizable and configurable search engine. You can customize the following:


### Search algorithms


### Document processing algorithms


