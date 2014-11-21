Pinwheel
========

A decision-tree blogging platform based on the graph database Neo4j

**Description**

Pinwheel uses neo4j to create a decision tree, to be used as a online guide or tutorial.  The origin use case is fairly specific:  Most instructional blogs are linear, and tell you how to use install or use a set of tools.  Pinwhell would allow you to create a decision tree, so that a user can select from several choices along the way.  

For example, a guide on building your first website first might have you choose a browser to work from, with an entry describing the developer tools for each browser, then after that decision is made, it could lead to a decision about whether or not to use a javascript framework, and which one to use. (etc. et. al.)

**Installation Instructions**

You must install Neo4j locally for this to work.  This is all a preliminary version, but a config file to have an external Neo4j will be added soon.

To install dependencies:

npm install

to run project:

coffee server/app.coffee
