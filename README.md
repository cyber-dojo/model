[![CircleCI](https://circleci.com/gh/cyber-dojo/model.svg?style=svg)](https://circleci.com/gh/cyber-dojo/model)

# cyberdojo/model

- The source for the [cyberdojo/model](https://hub.docker.com/r/cyberdojo/model/tags) Docker image.
- A docker-containerized stateless http micro-service for [https://cyber-dojo.org](http://cyber-dojo.org).

- - - -
* [ GET group_exists?(id)](docs/api.md#get-group_existsid)
* [POST group_create(manifests,options)](docs/api.md#post-group_createmanifestsoptions)
* [ GET group_manifest(id)](docs/api.md#get-group_manifestid)
* [POST group_join(id,indexes)](docs/api.md#post-group_joinidindexes)
* [ GET group_joined(id)](docs/api.md#get-group_joinedid)
- - - -
* [ GET kata_exists?(id)](docs/api.md#get-kata_existsid)
* [POST kata_create(manifest,options)](docs/api.md#post-kata_createmanifestoptions)
* [ GET kata_manifest(id)](docs/api.md#get-kata_manifestid)
* [ GET kata_events(id)](docs/api.md#get-kata_eventsid)
* [ GET kata_event(id,index)](docs/api.md#get-kata_eventidindex)
* [POST kata_ran_tests(id,index,files,stdout,stderr,status,summary)](docs/api.md#post-kata_ran_testsidindexfilesstdoutstderrstatussummary)
- - - -
* [GET alive?](docs/api.md#get-alive)  
* [GET ready?](docs/api.md#get-ready)
* [GET sha](docs/api.md#get-sha)
- - - -
![cyber-dojo.org home page](https://github.com/cyber-dojo/cyber-dojo/blob/master/shared/home_page_snapshot.png)
