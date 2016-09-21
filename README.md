# SPA

Surveillance paucity analysis app.

# Getting started

Download the ProMED database:

https://github.com/ecohealthalliance/promed_mail_scraper#downloading-pre-scraped-promed-data

### In case of using Meteor's mongodb instance:

Restore the data from the bucket into the locally running Meteor's mongodb instance:

> (requires the Meteor app to be running on port 5940)

```
mongorestore --port 5941 --drop --batchSize=10 --db meteor dump/promed
```

Run the app:

`make run`

### In case of utilizing the stand-alone mongodb server instance:

Restore the data from the bucket into the global mongodb instance:

`mongorestore --drop --batchSize=10 dump`

Run the app using the ProMED database:

```
MONGO_URL=mongodb://localhost:27017/promed make run
```
