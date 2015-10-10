# scriptybase

A poor's man liquibase. Your own database sql scripts updater/maintainer

#Motivation

Concept behind liquibase is smart and simple. Record patches applied on a database and check they wasn't modified latter. The main obstacle to adopt liquibase is it has it's own data model. Even sql file model implies a workflow change many teams are reluctant of. scriptybase bypassed that problem allowing any kind of "non standard complex database update workflow". See scriptybase as a transitional state while reluctant teams adopt liquibase

<pre>
(Programmer) - We need a database update workflow
(Sys Admin)  - Yes.
P - liquibase can help us
S - Yes, But We want to keep our proven-failed workflow, Does liquibase support that?
P - Uhmm, let's apply scriptybase.
... months later
S - scriptybase performs well, using it we realize our workflow has some flaws we need to solve
P - Let's apply liquibase
S - Ok this time.
</pre>

#Install

clone and link to your path

    $ git clone https://github.com/albfan/scriptybase.git
    $ cd scriptybase
    $ ln -s scriptybase.sh ~/bin/scriptybase

#Usage

    $ scriptybase <databaseType> <databaseName> <root_path> <db_patch_dir>

#Example

Scriptybase is extend by neccesity, and depends on thirdparty clients for each database. Go ahead and add yours.

- sqlite: supported
- postgres: planned
- mysql: planned
- sqlserver: planned
- whatever: support through sqlworkbench/j

#Test

Run test suite

    $ cd test/sqlite
    $ ./suite.sh

#Collaborate

Help files, parse arguments, implementations and test are going. Nothing blocking it. Just wait and check from time to time.
