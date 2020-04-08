### 7.3.0 (2020-04-08)

* move generation of graphs to background jobs

### 7.2.1 (2020-02-23)

* fix graph fails generation when any label is empty string

### 7.2.0 (2020-02-22)

* move graphs from assets to public directory

### 7.1.3 (2020-02-22)

* fix performance datatable never displays

### 7.1.2 (2020-02-21)

* make configs that return true/false end with ?
* add tests for configs that weren’t tested
* fix bugs in config#convert_size_to_bytes in response to testing

### 7.1.1 (2020-02-21)

* empty performance cache after running monitor status tests

### 7.1.0 (2020-02-20)

* allow performance cache size to be set by environment variable 
* move generation of history graph to cache_processors
* log warning in monitor logger if graphs fail to create
* monitor_status page won't try to display graphs if graph file does not exist

### 7.0.0 (2020-02-19)

* refactor of caching system to simplify the process
  * rename monitor_cache_service to cache_expiry_service
  * move generation of hourly graph to cache_processors
  * move generation of daily and monthly graphs to cache_processors
  * move performance datatable cache control to cache_processors
  * move caching of summary and historical data to cache_processors
  * move caching of test execution marker to cache_processors
  * move performance cache of performance data to cache_processors
  
### 6.2.0 (2020-02-17)

* use authentication for refreshing monitor tests
* add performance cache logger
* exceeding max performance cache size flushing the cache

### 6.1.0 (2020-02-17)

* change historical summary to show number of days instead of number of tests (original intent)
* default tests to connection tests
* update authorities to v2.2 configs
* add authority cerl_ld4l_cache

### 6.0.0 (2020-02-13)

* refactor generation of performance graphs to minimize db access and calculations
* shorten race_condition times for caching
* rename jobs_logger to be monitor_logger
* run monitoring tests in background
* move methods from QaServer to services
* use presenter to get failure data
* move controller validation code to module include
* limit historical data to configurable time period
* move time_period where clause construction to service

### 5.5.1 (2020-01-29)

* fix - check for nil before calling .each

### 5.5.0 (2020-01-10)

* use caching with expiry for monitor status page

### 5.4.0 (2020-01-07)

* adds config hour_offset_to_expire_cache
* deprecates config hour_offset_to_run_monitoring_tests (replaced by hour_offset_to_expire_cache)
* updates QaServer.monitoring_expires_at to use the new hour_offset_to_expire_cache config
* adds QaServer.cache_expiry that can be used for expiring all cached data
* add tests and exceptions for configs

### 5.3.0 (2019-12-19)

* optionally log browser and platform user agent info
* update to qa 5.3
  * add a request id to the search and find request headers
  * log exception for graph load failures
  * optionally include IP info at start of search/find linked data requests

### 5.2.1 (2019-12-13)

* fix - add defaults to the initializer generator template for new configs

### 5.2.0 (2019-12-10)

* cache performance data saving once a day when monitoring runs
* set monitoring to expire at 3am ET by default (configurable)
* setup travis-ci to run

### 5.1.0 (2019-12-10)

* allow suppression of performance data gathering

### 5.0.3 (2019-12-3)

* bug fix - use correct parameters for search query

### 5.0.2 (2019-12-3)

* bug fix - move individual params into request header to avoid lost subauths during testing

### 5.0.1 (2019-12-3)

* bug fix - force qa to not exclued performance header when find term returns jsonld

### 5.0.0 (2019-11-22)

* prepends for query updated to retain response_header in results

### 4.0.0 (2019-11-14)

* prepends for find and query updated to process request_header parameter

### 3.0.3 (2019-10-09)

* remove titles from graphs (previously set to '' which caused problems when deployed)

### 3.0.2 (2019-10-09)

* bug fix - make sure count is counting based on the current set of times

### 3.0.1 (2019-10-09)

* use old :load data when split :retrieve and :graph_load are not available
* bug fix - make sure count is counting based on the current set of times
* bug fix - add in missing translations
* bug fix - fix performance data table data style for retrieve
* bug fix - unsupported_action? for performance datatable handles all 0 stats

### 3.0.0 (2019-10-09)

* refactor performance data and graphs to include stats by action as well as by authority and time period
* adds pagination start_record parameter for LD4P cached data
* adds RDA Registry authority
* splits LCNAF into 2 authorities for LD4P cached data focused locnames and real world object focused locnames_rwo
* adds wikidata authority - NOTE: The first pass on fetching through this authority is non-performant.

### 2.2.3 (2019-09-11)

* do not process and store performance data if it wasn't returned in the result

### 2.2.2 (2019-09-10)

* handle stat calculation and formatting when 0 records or missing stats
* switch performance graph to stacked_bar
* Use 10th and 90th percentiles for datatable
* display day graph for every authority for default time period
* cache performance graphs
* don’t calculate low and high for graphs since they aren’t used
* don’t calcualte full request data for graphs since it isn’t used
* include authority data for performance graphs
* move some of the performance data construction code to services

### 2.2.1 (2019-09-04)

* config to optionally display of the performance graph/datatable
* add data table view of performance data

### 2.2.0 (2019-08-15)

* add performance graphs to monitor status page
* add ability to fetch a term through the UI
* update authority configs to latest versions

### 2.1.0 (2019-06-10)

* remove context from mesh_nlm; add direct match to locnames
* fix missing getty ids in linked data auth
* update ldpaths for locnames extended context
* fix oclcfast linked data config to properly configure passing uri instead of id 
* update code to work with qa 4.2.0
* update configs to QA_CONFIG_VERSION 2.1
* allow scenarios to specify whether the authority supports extended context for search
* add `encode: true` to search query param for all 2.0 configs
* Update locperformance_ld4l_cache_validation.yml
* add parentheses to complex ldpath to fix parse error
* update instructions to work with latest rails new command 

### 2.0.0 (2019-03-12)

* update code to work with qa 4.0.0
* update configs to QA_CONFIG_VERSION 2.0

### 1.2.3 (2019-03-07)

* change css class for failing tests to allow pingdom to check for the css class and notify sysop
* temporarily disable direct access to AGROVOC
* add vocabs: locperformance_ld4l_cache and locdemographics_ld4l_cache

### 1.2.2 (2018-11-21)

* update data tables to make authority names more prominent
* use consistent titles on each page to make it easier to tell where you are in the app

### 1.2.1 (2018-11-20)

* update Usage page to describe fetch and show options for retrieving a single term

### 1.2.0 (2018-11-20)

* update QA which includes...
    * extended QA API (e.g. list, reload, fetch)
    * fetch/show terms optionally returned as json-ld (default = json for backward compatibility)
* update dependencies for security vulnerabilities
* fix accuracy tests
* default term tests to use fetch instead of show when term identifier is a URI
* get list of authority names from QA AuthorityService

### 1.1.0 (2018-10-31)

* allow historical data to be displayed as graph or datatable (configuration)
* drive main nav menu from navmenu_presenter (configuration)
* Add better install instructions in README

### 1.0.0 (2018-09-24)

* drive URL base host path from qa engine mount location
* show graph of historical data on monitor status page (prereq: ImageMagick) 
* expand historical data to track all test results (passing and failing) (requires: db migrations)
* add bixby to control rubocop styles consistent with Hyrax
* add ability to use configurations to control app features
* fix security vulnerabilities

### 0.1.99 (2018-08-27)

* convert existing app code into a ruby engine
