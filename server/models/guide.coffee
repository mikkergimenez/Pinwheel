# guide.js
# Guide model logic.

neo4j = require("neo4j")

db = new neo4j.GraphDatabase(process.env["NEO4J_URL"] or process.env["GRAPHENEDB_URL"] or "http://localhost:7474")

Category = require("./category.coffee")
category = new Category()

ChoicePoint = require("./item.coffee")
choicePoint = new ChoicePoint()


Function::define = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc

# private constructor:
#Guide = module.exports = Guide = (_node) ->
class Guide

    constructor: (_node) ->
        @_node = _node

    @define '_id',
        get: -> return @_node.id
    @define 'title',
        get: -> return @_node.data["title"]  
        set: (title) -> return @_node.data["title"] = title
    @define 'body',
        get: -> return @_node.data["body"]
        set: (body) -> return @_node.data["body"] = body

    # public instance methods:
    save: (callback) ->
        @_node.save (err) ->
            callback err

    del: (callback) ->
        
        # use a Cypher query to delete both this guide and his/her following
        # relationships in one transaction and one network request:
        # (note that this'll still fail if there are any relationships attached
        # of any other types, which is good because we don't expect any.)
        query = [
            "MATCH (guide:Guide)"
            "WHERE ID(guide) = {guideId}"
            "DELETE guide"
            "WITH guide"
            "MATCH (guide) -[rel:follows]- (other)"
            "DELETE rel"
        ].join("\n")
        params = guideId: @id
        db.query query, params, (err) ->
            callback err

    follow:  (other, callback) ->
        @_node.createRelationshipTo other._node, "IN_CATEGORY", {}, (err, rel) ->
            callback err
        
    unfollow: (other, callback) ->
        query = [
            "MATCH (guide:Guide) -[rel:follows]-> (other:Guide)"
            "WHERE ID(guide) = {guideId} AND ID(other) = {otherId}"
            "DELETE rel"
        ].join("\n")
        params =
            guideId: @id
            otherId: other.id

        db.query query, params, (err) ->
            callback err

    # calls callback w/ (err, following, others) where following is an array of
    # guides this guide follows, and others is all other guides minus him/herself.
    getFollowingAndOthers: (callback) ->
    
        # query all guides and whether we follow each one or not:
        # COUNT(rel) is a hack for 1 or 0
        query = [
            "MATCH (guide:Guide), (other:Guide)"
            "OPTIONAL MATCH (guide) -[rel:follows]-> (other)"
            "WHERE ID(guide) = {guideId}"
            "RETURN other, COUNT(rel)"
        ].join("\n")
        params = guideId: @id
        guide = this

        db.query query, params, (err, results) ->
            return callback(err)  if err
            following = []
            others = []
            i = 0

            while i < results.length
                other = new Guide(results[i]["other"])
                follows = results[i]["COUNT(rel)"]
                if guide.id is other.id
                    continue
                else if follows
                    following.push other
                else
                    others.push other
                i++
            callback null, following, others

    findByCategoryId: (category_id, callback) ->
        console.log "Loading guides in category page"
        query = [
            "MATCH (guide:Guide)-[rel:IN_CATEGORY]->(category:Category)"
            "WHERE ID(category) = "+category_id
            "RETURN guide, category"
        ].join("\n")

        db.query query, null, (err, results) ->

            return callback(err) if err
            guides = results.map((result) ->
                guide = new Guide(result["guide"])
                category = new Category(result["category"])
                _id: guide["_id"]
                title: guide["title"]
                body: guide["body"]
            )
            callback null, guides

    findWithNodesById: (id, callback) ->
        query = [
            "MATCH (guide:Guide)"
            "WHERE ID(guide) = " + id
            "MATCH (guide)-[rel:IN_CATEGORY]->(category:Category)"
            "OPTIONAL MATCH (choice_point:ChoicePoint)-[rel:LINKED_TO]->(guide)"
            "RETURN guide, choice_point, category"
        ].join("\n")

        console.log query

        db.query query, null, (err, results) ->

            return callback(err) if err

            guides = results.map((result) ->
                guide = new Guide(result["guide"])
                choice_points = new ChoicePoint(result["choice_point"])
                if not choice_points._node?
                    choice_points = null
                category = new Category(result["category"])
                _id: guide["_id"]
                title: guide["title"]
                body: guide["body"]
                choice_points: choice_points
                category: category
            )
            console.log "GUIDES"+guides[0]
            callback null, guides[0]


    # static methods:
    findById: (id, callback) ->
        query = [
            "MATCH (guide:Guide)-[rel:IN_CATEGORY]->(category:Category)"
            "WHERE ID(guide) = "+id
            "RETURN guide, category"
        ].join("\n")

        db.query query, null, (err, results) ->
            return callback(err)  if err
            guides = results.map((result) ->
                guide = new Guide(result["guide"])
                category = new Category(result["category"])
                
                #return { id: result['guide']['id'], text: result['guide']['_data']['data']['text'] };
                _id: guide["_id"]
                text: guide["text"]
                category: category
            )
            callback null, guides[0]
        """            
        db.getNodeById id, (err, node) ->
            return callback(err)  if err
        """

    findAll: (callback) ->
        query = [
            "MATCH (guide:Guide)"
            "RETURN guide"
        ].join("\n")
        db.query query, null, (err, results) ->
            return callback(err)  if err
            guides = results.map((result) ->
                guide = new Guide(result["guide"])
                
                #return { id: result['guide']['id'], text: result['guide']['_data']['data']['text'] };
                id: guide["id"]
                text: guide["text"]
            )
            callback null, guides

    create: (data, callback) ->
        # construct a new instance of our class with the data, so it can
        # validate and extend it, etc., if we choose to do that in the future:


        node = db.createNode(data)
        guide = new Guide(node)
        
        # but we do the actual persisting with a Cypher query, so we can also
        # apply a label at the same time. (the save() method doesn't support
        # that, since it uses Neo4j's REST API, which doesn't support that.)

        query = [
            "CREATE (guide:Guide {data})"
            "RETURN guide"
        ].join("\n")

        params = data: data
        db.query query, params, (err, results) ->
            return callback(err)  if err
            guide = new Guide(results[0]["guide"])
            category.findById data.category, (error, category) =>
                guide.follow category, () ->
                    console.log("Now Following!")

            callback null, guide

        return data
 
module.exports = Guide