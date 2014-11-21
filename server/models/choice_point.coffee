# choice_point.js
# ChoicePoint model logic.

neo4j = require("neo4j")

db = new neo4j.GraphDatabase(process.env["NEO4J_URL"] or process.env["GRAPHENEDB_URL"] or "http://localhost:7474")

Guide = require("./guide.coffee")
guide = new Guide()

Function::define = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc

# private constructor:
#ChoicePoint = module.exports = ChoicePoint = (_node) ->
class ChoicePoint

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
        
        # use a Cypher query to delete both this choice_point and his/her following
        # relationships in one transaction and one network request:
        # (note that this'll still fail if there are any relationships attached
        # of any other types, which is good because we don't expect any.)
        query = [
            "MATCH (choice_point:ChoicePoint)"
            "WHERE ID(choice_point) = {choicePointId}"
            "DELETE choice_point"
            "WITH choice_point"
            "MATCH (choice_point) -[rel:follows]- (other)"
            "DELETE rel"
        ].join("\n")
        params = choicePointId: @id
        db.query query, params, (err) ->
            callback err

    follow:  (other, callback) ->
        console.log "LINKED_TO"
        @_node.createRelationshipTo other._node, "LINKED_TO", {}, (err, rel) ->
            callback err
        
    unfollow: (other, callback) ->
        query = [
            "MATCH (choice_point:ChoicePoint) -[rel:follows]-> (other:ChoicePoint)"
            "WHERE ID(choice_point) = {choicePointId} AND ID(other) = {otherId}"
            "DELETE rel"
        ].join("\n")
        params =
            choicePointId: @id
            otherId: other.id

        db.query query, params, (err) ->
            callback err

    # calls callback w/ (err, following, others) where following is an array of
    # choice_points this choice_point follows, and others is all other choice_points minus him/herself.
    getFollowingAndOthers: (callback) ->
    
        # query all choice_points and whether we follow each one or not:
        # COUNT(rel) is a hack for 1 or 0
        query = [
            "MATCH (choice_point:ChoicePoint), (other:ChoicePoint)"
            "OPTIONAL MATCH (choice_point) -[rel:follows]-> (other)"
            "WHERE ID(choice_point) = {choicePointId}"
            "RETURN other, COUNT(rel)"
        ].join("\n")
        params = choicePointId: @id
        choice_point = this
        db.query query, params, (err, results) ->
            return callback(err)  if err
            following = []
            others = []
            i = 0

            while i < results.length
                other = new ChoicePoint(results[i]["other"])
                follows = results[i]["COUNT(rel)"]
                if choice_point.id is other.id
                    continue
                else if follows
                    following.push other
                else
                    others.push other
                i++
            callback null, following, others

    # static methods:
    findById: (id, callback) ->
        db.getNodeById id, (err, node) ->
            return callback(err) if err
            callback null, new ChoicePoint(node)

    findAll: (callback) ->
        query = [
            "MATCH (choice_point:ChoicePoint)"
            "RETURN choice_point"
        ].join("\n")
        db.query query, null, (err, results) ->
            return callback(err)  if err
            choice_points = results.map((result) ->
                choice_point = new ChoicePoint(result["choice_point"])
                
                #return { id: result['choice_point']['id'], text: result['choice_point']['_data']['data']['text'] };
                
                _id: choice_point["_id"]
                title: choice_point["title"]
                body: choice_point["body"]

            )
            callback null, choice_points

    create: (data, callback) ->
        # construct a new instance of our class with the data, so it can
        # validate and extend it, etc., if we choose to do that in the future:
        node = db.createNode(data)
        choice_point = new ChoicePoint(node)
        
        # but we do the actual persisting with a Cypher query, so we can also
        # apply a label at the same time. (the save() method doesn't support
        # that, since it uses Neo4j's REST API, which doesn't support that.)
        query = [
            "CREATE (choice_point:ChoicePoint {data})"
            "RETURN choice_point"
        ].join("\n")

        console.log "GUIDE ID" + data.guide

        params = data: data
        db.query query, params, (err, results) ->
            return callback(err)  if err
            choice_point = new ChoicePoint(results[0]["choice_point"])
            guide.findById data.guide, (error, guide) =>
                choice_point.follow guide, (err) ->
                    console.log "ERROR"
                    console.log err
                    console.log("Now Linked!")

            callback null, choice_point

        return data

module.exports = ChoicePoint