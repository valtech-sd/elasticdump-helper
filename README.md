# dump-query (ElasticDump frontend) README

## Summary

Dump-query.sh is a bash script along with supporting files (environment variables) to run the [ElasticDump](https://github.com/elasticsearch-dump/elasticsearch-dump) utility to pull specific data out of ElasticSearch (ES), the data being specified in the QUERY that is run.

In theory, ANY valid ES query can be run by this bash script and produces result output inside files. 

Authentication against ES is done using an authentication header (standard http basic authentication). See [Dependencies](#dependencies)

## Dependencies

* Bash (or another Linux shell environment.)
* Node Version Manager ([nvm](https://github.com/nvm-sh/nvm) for macOS/linux, [nvm-windows](https://github.com/coreybutler/nvm-windows#bulb-whats-the-big-difference) for windows)
    - If you must, you can just run with plain old NodeJS for your platform, but a version manager is highly recommended!
* Install ElasticDump per the instructions in https://github.com/elasticsearch-dump/elasticsearch-dump
    - Typically, this can be done using NPM globally with `npm install elasticdump -g elasticdump`. Since this is a CLI tool, a global installation should not particularly problematic.
* Create an environment file with your host and authorization header. For the structure of the file, copy **dump-query-template.env** into **dump-query.env** and see the comments inside the file.

## Syntax & Examples

**Syntax**

```bash
$ ./dump-query.sh "INDEX-NAME-OR-PATTERN" /path/to/query.json /path/to/result.json
```
- **INDEX-NAME-OR-PATTERN** - is the ES index name (or pattern to match) where the data will come from. It can be a specific index, or a pattern (using wildcards) that matches multiple indexes.
- **/path/to/query.json** - is the path to a file containing a valid ES query in JSON format. See [ES Queries](#es-queries) for more details.
- **/path/to/result.json** - is a path to a file, which must not exist, where the data will be saved into.

> **Note:** The host is NOT specified in the command line. That is because the host is instead specified in the **dump-query.env** file along with the proper authentication. Need a tool to generate your authentication header? Try the [Basic Auth Header Generator](https://www.debugbear.com/basic-auth-header-generator) by DebugBear.

**Example**

```bash
$ ./dump-query.sh "logstash-*" ./queries/query-received-message-times.json ./results/result-week2.json
```
This example will run the ES query in the queries sub-directory called **query-received-message-times.json** to extract data from all the indexes matching **logstash-\*** in the host specified in **dump-query.env** with credentials also provided in that environment file.

## ES Queries

Discussing ES queries is well beyond the scope of this README. The ES Query DSL is covered in detail in the [Elastic Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html) page. Please refer to that page for full details.

However, if you have access to a Kibana dashboard, it's possible to use the **DISCOVER** tab to create a query and then inspect the Query DSL created by Kibana. Once you have a QUERY that returns the data you are interested in, select the **INSPECT** menu item. Once the inspect tab appears, click on **REQUEST** to see the request sent by Kibana. Copy this to your favorite text editor! Note that this request generally has a lot of entries that you might be able to carefully remove from the JSON for the purposes of dumping data (just make sure you don't break the JSON nesting). For example the following can generally all be removed from the query for use with this dump script: aggregations, sort, stored_fields, script_fields, docvalue_fields, highlight. Generally, **_source** (to select specific fields you want in your output) and **query** (to filter to only the records you are interested in) are sufficient in your query.

### Query Examples explained

The **query-example-select-star.json** is the equivalent if a "select \* where timestamp between some-date and some-other-date" in standard SQL. It gets EVERY field available in an index and only filters for records in a specific timestamp range.

The **query-example.json** performs the following:

- returns only the fields: **timestamp**, **app_name**, **context.messageId**, **dataparsed.timestamp**.
- filters for records that:
    - contain the phrase "message received" in the **data** field. Since there are no wildcards in the string, this will be a "contains exact string" match meaning any string that contains the string in any part of the source will match.
    - contains any value in **dataparsed.timestamp** (so this field must be present in the record.)
    - The field **hostname** is equal to "some-host-name-here".
    - The field **app_name** is equal to "my-app-instance-\*" but with a wildcard to match any value after "my-app-instance-".
    - The field **@timestamp** is a valid timestamp and inside a specific range.

## Batch Limit & Concurrency

You can edit the script's constants ED_LIMIT and ED_CONCURRENCY to pass ElasticDump's own **limit** and **concurrency** arguments.

* limit - How many objects to move in batch per operation limit is approximate for file streams. This script's default is 5000 which is different than ElasticDump's default of 100.
* concurrency - The maximum number of requests the can be made concurrently to a specified transport. This script's default is 3 which is different than ElasticDump's default of 1.

To add further ElasticDump arguments, edit the script to suit.

Refer to [ElasticDump's options documentation](https://github.com/elasticsearch-dump/elasticsearch-dump#options) for further details.