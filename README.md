# QaServer

This rails engine can be installed into your app to serve as a Questioning Authority (QA) Server for accessing external authorities.  It is part of a larger architecture supporting linked data authority access.  From this engine, you can send a search query and get back multiple results OR you can fetch a single term.  The engine provides UI for monitoring connections to configured authorities and the ability to check the current status of a single authority to determine if it is up and running now. 

## Reference

* [Architecture for Authority Lookup](https://wiki.duraspace.org/x/84E2BQ) document describes the authority access and normalization layer that provides applications with a consistent output for processing.
* [Authority aggregation and indexing](https://wiki.duraspace.org/display/ld4lLABS/Authority+aggregation+and+indexing) document describes the technology used for caching authority data.
* [samvera/questioning_authority](https://github.com/samvera/questioning_authority) (QA) is the gem that provides access to external authorities and normalizes the results.  See the [Linked Open Data (LOD) Authorities](https://github.com/samvera/questioning_authority#linked-open-data-lod-authorities) section for details on the primary part of QA that is used by this engine.
* [ruby-rdf/linkeddata](https://github.com/ruby-rdf/linkeddata) is a gem that processes linked data in a number of RDF formats.
* [LD4P/linked_data_authorities](https://github.com/LD4P/linked_data_authorities) holds predefined Questioning Authority configurations that work with this qa_server engine.


## Setup

### Compatibility

Tested with...

* Ruby 2.4.3
* Rails 5.1.6

### Optional Prerequisites

Only required if you want to generate status charts.  Generated charts will be saved in 
`app/assets/images/qa_server/charts` directory.  By default status is displayed in a table.

1. [ImageMagick](http://www.imagemagick.org/)
2. job queue processor of your choice

### Installation Instructions

#### Adding the engine dependencies

Add these lines to your application's Gemfile:

```ruby
gem 'qa_server'
gem 'qa'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install qa_server
```

#### Install the engine and run migrations

```bash
$ rails g qa_server:install
$ rake db:migrate
```

If upgrading instead of installing, see the Release notes for steps you may need to take manually since you won't be running the installer.

#### Setting up monitoring

Monitoring runs once a day as a background job.  

##### Configuring cache expiration

There are several configurations that control when the monitoring job will execute.

```
    # Preferred time zone for reporting historical data and performance data
    # @param [String] time zone name
    # @see https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html for possible values of TimeZone names
    attr_writer :preferred_time_zone_name
    def preferred_time_zone_name
      @preferred_time_zone_name ||= 'Eastern Time (US & Canada)'
    end

    # Set preferred hour to expire caches related to slow running calculations (e.g. monitoring tests, performance data)
    # @param [Integer] count of hours after midnight (0-23 with 0=midnight)
    # @raise [ArgumentError] if offset is not between 0 and 23
    # @example
    #   For preferred_time_zone_name of 'Eastern Time (US & Canada)', use 3 for slow down at midnight PT/3am ET
    #   For preferred_time_zone_name of 'Pacific Time (US & Canada)', use 0 for slow down at midnight PT/3am ET
    def hour_offset_to_expire_cache=(offset)
      raise ArgumentError, 'offset must be between 0 and 23' unless (0..23).cover? offset
      @hour_offset_to_expire_cache = offset
    end
```

With the default values set for the cache configurations, the cache will expire at midnight Pacific Time/3am Eastern Time.

##### Process for updating monitoring tests

Monitoring works in conjuction with the cache.  When the cache expires, the monitoring tests will run the next time the monitor status page is accessed.  When the monitor status page loads, it attempts to get the data for the page from the cache.  If the cache has expired, it will get the previous day's data and kick off a background job to run the tests and update the cache.

##### Controlling when tests run

Because this process is launched by access to the monitor status page, it will not by default run the monitoring tests everyday.  In our system, we set up Pingdom to access the monitor status page hourly around the clock.  If an error occurs during the latest testing, the monitor status page includes a CSS class `summary-status-bad` and displays error results.  Pingdom is configured to send a notification if the `summary-status-bad` CSS class is on the page, letting us know that we need to look into a problem with authority access.

##### Setting up background jobs

Reference: https://guides.rubyonrails.org/active_job_basics.html

Since this job is not critical for end users, you can set up jobs to be processed by the ruby provided in-memory job queue.  The risk here is that if the server restarts or some other failure occurs, jobs in that queue are lost.  If this is unacceptable for your system, then you will want to setup a 3rd party job queue ([more info...](https://guides.rubyonrails.org/active_job_basics.html#starting-the-backend)).

To configure in-memory job queue, add the following to config/environments/production.rb

```
  config.active_job.queue_adapter = :async # runs in-memory; a crash will lose the job
```

#### Test the install

* Start rails server with `rails s`
* You should see the Home page.  Click the other nav menus to be sure you see content there as well.
* On Authorities List, click the URL for one of the authorities to confirm you get data.
* On Check Status, select one authority from the selection list and confirm that tests pass.
* Clicking on Monitor Status will run all tests, which is very slow.  When it completes, it will have confirmed that the database tables are setup correctly.  You can expect all tests to pass, although, there is a possibility that one or more authorities are down at the moment you run the tests.  If all fail, there may be an installation problem.  If only a few fail, it is more likely a problem with the authority.

#### Trouble Shooting

Common problems:

* If complaints about a table not existing, either the migrations were not copied over or have not run.
* All tests fail could mean that the required gems were not installed.  Look for gems `qa` and `linkeddata`.
* If some tests fail with a comment that the results are not RDF, confirm that gems `qa` and `linkeddata` are installed.  Confirm that `qa` gem is using the `min-context` branch.

## Supported Authorities

### Authorities that come with QA

There are a few authorities that are part of the QA gem.  All directly access the external authority.

* direct access to OCLC FAST
  * TEST QUERY: http://localhost:3000/qa/search/linked_data/oclc_fast?q=Cornell&maximumRecords=3
  * TEST FETCH: http://localhost:3000/qa/show/linked_data/oclc_fast/2
* direct access to AGROVOC
  * TEST QUERY: http://localhost:3000/qa/search/linked_data/agrovoc?q=milk&lang=en&maxRecords=3
  * TEST FETCH: http://localhost:3000/qa/show/linked_data/agrovoc/c_9513
* direct access to Library of Congress for term fetch only
  * TEST QUERY: _not supported_
  * TEST FETCH: http://localhost:3000/qa/show/linked_data/loc/no2002053226
  
### Predefined Configurations in LD4P/linked_data_authorities

All authorities defined in [LD4P/linked_data_authorities](https://github.com/LD4P/linked_data_authorities) are included in this engine.  When you run the install task, they will be copied to `config/authorities/linked_data`.  If you do not want to support a particular authority, you can remove it from this directory and the corresponding validation file in the `scenarios` sub-directory.

Configurations exist for a number of other common authorities that can be used by your QA Server.  When possible, each configuration comes in two varieties...

* _AUTHORITY_NAME__direct - configuration can be used as is to access the external authority directly
* _AUTHORITY_NAME__ld4l_cache - configuration can be used as is to access the authorities through the cache created as part of the Linked Data for Libraries Labs grant and continuing to be expanded under the Linked Data for Production 2 grant.

Configurations define how to access an authority and how to decode the ontology predicates to extract and convert the data to normalized data.  The predefined configurations live in [qa_server/config/authorities/linked_data](https://github.com/LD4P/qa_server/tree/master/config/authorities/linked_data).

### Write your own configuration

#### Authority requirements

If you want to access an authority for which there isn't a configuration, you can write your own.  There are only two requirements to be able to access an authority.
 
1. For search access, the authority must have a URL API defined that accepts a string search query.
1. For term access, the authority must either support accessing the URI for the term OR provide a URL API which takes an id or URI as a parameter.
1. For both search and term, the returned results must be in a linked data format.

#### Writing the configuration

Instructions for writing your own configuration can be found in the ([QA gem README](https://github.com/samvera/questioning_authority#configuring-a-lod-authority)).  You are encouraged to use consistent names for common prameters, including the following...

* q - search query value that the user types
* maxRecords - to identify the max number of records for the authority to return if the authority supports limiting the number of returned records
* lang - limit string values to the identified language if the authority supports language specific requests

## Using the configuration

Add your new configuration to `this_app/config/authorities/linked_data`

TEST QUERY: http://localhost:3000/qa/search/linked_data/_AUTHORITY_NAME__direct?q=your_query&maxRecords=3
TEST FETCH: http://localhost:3000/qa/show/linked_data/_AUTHORITY_NAME__direct/_ID_OR_URI_

Substitute the name of the configuration file for _AUTHORITY_NAME__direct in the URL.
Substitute a valid ID or URI for _ID_OR_URI_ in the URL, as appropriate.  NOTE: Some authorities expect an ID and others expect a URI.


### Expected Results

#### Search Query Results

This search query... http://localhost:3000/qa/search/linked_data/oclc_fast/personal_name?q=Cornell&maximumRecords=3
              
will return results like...
 
```
[{"uri":"http://id.worldcat.org/fast/5140","id":"5140","label":"Cornell, Joseph"},
 {"uri":"http://id.worldcat.org/fast/72456","id":"72456","label":"Cornell, Sarah Maria, 1802-1832"},
 {"uri":"http://id.worldcat.org/fast/409667","id":"409667","label":"Cornell, Ezra, 1807-1874"}]
```

#### Term Fetch Results

This term fetch... http://localhost:3000/qa/show/linked_data/oclc_fast/530369
                   
will return results like...

```
{"uri":"http://id.worldcat.org/fast/530369",
 "id":"530369","label":"Cornell University",
 "altlabel":["Ithaca (N.Y.). Cornell University","Kornelʹskii universitet","Kʻang-nai-erh ta hsüeh"],
 "sameas":["http://id.loc.gov/authorities/names/n79021621","https://viaf.org/viaf/126293486"],
 "predicates":{
   "http://purl.org/dc/terms/identifier":"530369",
   "http://www.w3.org/2004/02/skos/core#inScheme":["http://id.worldcat.org/fast/ontology/1.0/#fast","http://id.worldcat.org/fast/ontology/1.0/#facet-Corporate"],
   "http://www.w3.org/1999/02/22-rdf-syntax-ns#type":"http://schema.org/Organization",
   "http://www.w3.org/2004/02/skos/core#prefLabel":"Cornell University",
   "http://schema.org/name":["Cornell University","Ithaca (N.Y.). Cornell University","Kornelʹskii universitet","Kʻang-nai-erh ta hsüeh"],
   "http://www.w3.org/2004/02/skos/core#altLabel":["Ithaca (N.Y.). Cornell University","Kornelʹskii universitet","Kʻang-nai-erh ta hsüeh"],
   "http://schema.org/sameAs":["http://id.loc.gov/authorities/names/n79021621","https://viaf.org/viaf/126293486"]}}
```

## Connection and Accuracy Validations

Validations come in two flavors...
* connection validation - PASS if a request gets back a specified minimum size result set from an authority; otherwise, FAIL.  
* accuracy test - PASS if a specific result is returned by a specified position (e.g. uri is in the top 10 results); otherwise, FAIL.

The validations can be defined in a file with a matching file name in the [scenarios directory](https://github.com/LD4P/qa_server/tree/master/config/authorities/linked_data/scenarios).  For example, direct access to the AgroVoc authority, access is configured in [config/authorities/linked_data/agrovoc_direct.json](https://github.com/LD4P/qa_server/blob/master/config/authorities/linked_data/agrovoc_direct.json) and the validations are defined in [config/authorities/linked_data/scenarios/agrovoc_direct_validation.yml](https://github.com/LD4P/qa_server/blob/master/config/authorities/linked_data/scenarios/agrovoc_direct_validation.yml)

The UI for qa_server provides access to running connection validation and accuracy tests in the Check Status navigation menu item.

## Non linked-data authority access

QA Server is based on the [Questioning Authority gem](https://github.com/samvera/questioning_authority).  As such, it can be used to serve up controlled vocabularies defined in one of three ways.

1. locally defined controlled vocabularies
1. specifically supported external authorities (non-linked data)
1. configurable access to linked data authorities

This document addresses the use of QA Server app for access to linked data authorities.  You can reference Questioning Authorities
[documentation](https://github.com/samvera/questioning_authority/blob/master/README.md) for more information on the other uses.


## Contributing

*Have a suggestion for code improvements or new linked data authorities?*  Submit an issue with your request.  For new authorities, include links to the authority's linked data API and other access documentation.
  
*Have code improvements you've written or a configuration for a new authority you'd like to submit?* Submit a PR and your changes will be reviewed for possible inclussion.  If you want to make a substantial change, you may want to express your ideas in an issue first for discussion.


## License
The gem is available as open source under the terms of the [Apache License](https://www.apache.org/licenses/LICENSE-2.0).

