Refactoring SCR Annotations
===========================

Tools
-----

This branch contains a bash script `compare.sh`, which allows comparing the declarative services and metatype xml files of two jar files.

It takes the Oak module (e.g. oak-core) and the version (e.g. 1.8-SNAPSHOT) as arguments. Optionally also a path that points to the location of an XML file inside the bundle.

    ./compare.sh oak-core 1.8-SNAPSHOT OSGI-INF/org.apache.jackrabbit.oak.plugins.index.datastore.DataStoreTextProviderService.xml

To better undertand what the script does you can run bash in debug mode:

    bash -x ./compare.sh oak-core 1.8-SNAPSHOT

Any output of the script is written to `./comparison/` and cleared when the script is run the next time.

The baseline jar file is looked up in the local maven repository (i.e. `~/.m2/repository`).

Note
----

There are some differences in the XML files that do not represent a semantic difference. Therefore the diff still needs to be manually inspected.
 
