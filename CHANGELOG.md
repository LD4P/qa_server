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
