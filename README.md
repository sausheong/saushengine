# SaushEngine

_This is work in progress, please do not use yet!_

SaushEngine is a simple and customizable search engine that allows you to crawl through anything and anywhere for data. You can use it to crawl an intranet or a file server for documents, spreadsheets and slides or even your computer.

![http://sweetclipart.com/cute-white-baby-seal-888](images/baby_seal.png =200x)

## How it works

The search engine has two parts:

1. _Spider_ - goes out to collect data for the search engine. The Spider includes the message queue and the index database. The Spider crawls through URLs in the message queue, given initial seeds in the queue, processes the documents found and saves data into the index database. The Spider is controlled with a web interface.
2. _Digger_ - allows your user to search through the index database. The Digger algorithms are customisable and configurable.


## Features

The following are features found in SaushEngine:

1. Multiple parallel crawlers for creating the search index
2. Crawlers can process multiple document formats including HTML, Microsoft Word, Adobe PDF and many others
3. Crawlers can be customized to search specific domains only
4. Crawlers can search through NTLM protected sites (Sharepoint etc)
5. Web-based crawler management interface
6. Search can be specific to mime-types
7. Search can be specific to domains or hosts
8. Highly customizable and configurable settings for search algorithms

## Installation

To install SaushEngine, do the following steps in sequence:

1. Install JRuby (preferably use [rbenv](https://github.com/sstephenson/rbenv) with the [ruby-build](https://github.com/sstephenson/ruby-build) plugin installed)
2. Install [Postgres (9.3)](http://www.postgresql.org/). Make sure you have the correct permissions set up for your current user.
3. Install [RabbitMQ](https://www.rabbitmq.com/). On certain platforms this might already been installed
4. Run `gem install bundler` to install [Bundler](http://bundler.io/), followed by `bundle install` to download and install the rest of the gems
5. Run the `start` script (Linux variant only) to set up the database and the permissions



## Running SaushEngine

You can run SaushEngine in either _development_ mode or _production_ mode (production mode here really only means you're running the servers as daemons with the environment set to production, it doesn't mean SaushEngine is really production capable now).

To run SaushEngine in _development_ mode, just use [Foreman](https://github.com/ddollar/foreman):

    $ foreman start
    
This should start your RabbitMQ server as well as the Spider and the Digger.

To run SaushEngine in _production_ mode, the assumption is that RabbitMQ is already running, and we're only running the Spider and the Digger in daemon mode:

    $ ./start
    
To stop SaushEngine in _production_ mode, use the stop script:

    $ ./stop
    
After starting up the Spider, you can proceed to configure and deploy your spiders!

1. Go to http://localhost:5914 to see the Spider web interface. This interface allows you to control and configure the Spider's settings
2. If you're crawling through NTLM authentication protected sites, remember add the necessary credentials in the settings page
3. Add the seed URL into the queue
4. Start up one or more spiders
5. You should see the spiders running now, hard at work in processing and adding pages into the index


With your spiders now hard at work, you can start using the search engine! Go to http://localhost:4199 to start using SaushEngine.


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

The Digger allows your users to query the documents you have crawled and processed in your index database.


## Customizing SaushEngine

SaushEngine is a highly customizable and configurable search engine. You can customize the following:


### Search algorithms

The default built-in search algorithms are:

1. Frequency of words
2. Location of words
3. Distance between one word and another

Each algorithm is assigned an importance percentage, which determines how important the algorithm is in getting the right results. You can tweak this accordingly. More importantly you can add additional algorithms.



### Document processing algorithms

SaushEngine has built-in processing capabilities to process HTML as well as various types of file formats supported by [Apache Tika](http://tika.apache.org/). You can customize or extend this accordingly.

