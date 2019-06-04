---
name: 'Request a New Dataset for Sinopia:'
about: This issue template is for LD4P2 requests for a new data source to be added to QA.

---

_Please only use this issue template for LD4P2 requests for a new data source to be added to QA. If your requesting changes to how a dataset currently available in QA is treated, please use the indexing bug issue template._

__For LD4P2 partners and cohorts:__


Please perform each task listed below. (Email sf433 @ cornell dot edu with questions):
- [ ] Please consult the LD4P2 QA Authority Support Plan (https://github.com/LD4P/qa_server/wiki/Authority-Lookup-Support-Plan-for-Sinopia) to confirm the dataset isn't already being supported.
- [ ] Identify the data source: (Include the Data Source Name, its homepage URL, and any relevant API and/or download information to aid in caching.)
- [ ] QA has the ability to provide contextual information about an entity during the look-up experience. In order to do so, decisions need to be made about how to index the RDF descriptions of entities in the dataset. Add a new tab and indexing information for the data source to the following spreadsheet: https://docs.google.com/spreadsheets/d/1rPvEoP9iYNkxJ0eWC8gXe3ci7e6mhW0da59xkGhadi0/edit?usp=sharing.  (See the existing LCNAF tab in the spreadsheet as an example)



Next steps: 

Once the above actions have taken place, a link to a YAML file will be shared with the requestor via a comment in the issue in order to complete Accuracy Test, https://github.com/LD4P/qa_server/wiki/Writing-Tests-for-an-Authority#accuracy-test. Edit directly the YAML file in Github, save. Create a Pull Request to be reviewed. Be sure to including a meaningful commit message (e.g. adding accuracy tests for Authority X). 

Context on Accuracy Tests: In order to make sure the QA search behavior (recall and relevancy) are meeting expectations, QA uses YAML to define test parameters. These parameters include the ability to declare for a particular text string searched, the results should include a particular resource (identified by a URI) and what is the maximum position in the results the resource should be found.)


_Please note, all requests for new data sources in QA will be prioritized by the LD4P2 project. Due to time restrictions there is no guarantee that all requests will be added to QA during the lifetime of the LD4P2 grant; regardless of resources it is still useful to know which datasets the community would find useful in such a lookup service._
