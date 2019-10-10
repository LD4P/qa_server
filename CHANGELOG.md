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
