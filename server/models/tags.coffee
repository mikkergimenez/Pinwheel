# tag.js
# Tag model logic.

neo4j = require("node-neo4j")

db = new neo4j.GraphDatabase(process.env["NEO4J_URL"] or process.env["GRAPHENEDB_URL"] or "http://localhost:7474")

Function::define = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc

# private constructor:
#Tag = module.exports = Tag = (_node) ->
class Tag

    constructor: (_node) ->
        @_node = _node

    @define 'id',
        get: -> return @_node.id
    @define 'text',
        get: -> return @_node.data["text"]  
        set: (text) -> return @_node.data["text"] = text
    @define 'type',
        get: -> return @_node.data["type"]
        set: (type) -> return @_node.data["type"] = type

    # public instance methods:
    save: (callback) ->
        @_node.save (err) ->
            callback err

    del: (callback) ->
        
        # use a Cypher query to delete both this tag and his/her following
        # relationships in one transaction and one network request:
        # (note that this'll still fail if there are any relationships attached
        # of any other types, which is good because we don't expect any.)
        query = [
            "MATCH (tag:Tag)"
            "WHERE ID(tag) = {tagId}"
            "DELETE tag"
            "WITH tag"
            "MATCH (tag) -[rel:follows]- (other)"
            "DELETE rel"
        ].join("\n")
        params = tagId: @id
        db.query query, params, (err) ->
            callback err

    follow:  (other, callback) ->
        @_node.createRelationshipTo other._node, "follows", {}, (err, rel) ->
            callback err
        
    unfollow: (other, callback) ->
        query = [
            "MATCH (tag:Tag) -[rel:follows]-> (other:Tag)"
            "WHERE ID(tag) = {tagId} AND ID(other) = {otherId}"
            "DELETE rel"
        ].join("\n")
        params =
            tagId: @id
            otherId: other.id

        db.query query, params, (err) ->
            callback err

    # calls callback w/ (err, following, others) where following is an array of
    # tags this tag follows, and others is all other tags minus him/herself.
    getFollowingAndOthers: (callback) ->
    
        # query all tags and whether we follow each one or not:
        # COUNT(rel) is a hack for 1 or 0
        query = [
            "MATCH (tag:Tag), (other:Tag)"
            "OPTIONAL MATCH (tag) -[rel:follows]-> (other)"
            "WHERE ID(tag) = {tagId}"
            "RETURN other, COUNT(rel)"
        ].join("\n")
        params = tagId: @id
        tag = this
        db.query query, params, (err, results) ->
            return callback(err)  if err
            following = []
            others = []
            i = 0

            while i < results.length
                other = new Tag(results[i]["other"])
                follows = results[i]["COUNT(rel)"]
                if tag.id is other.id
                    continue
                else if follows
                    following.push other
                else
                    others.push other
                i++
            callback null, following, others

    # static methods:
    find: (id, callback) ->
        db.getNodeById id, (err, node) ->
            return callback(err)  if err
            callback null, new Tag(node)

    findById: (callback) ->
        query = [
            "MATCH (tag:Tag)"
            "RETURN tag"
        ].join("\n")
        db.query query, null, (err, results) ->
            return callback(err)  if err
            tags = results.map((result) ->
                tag = new Tag(result["tag"])
                
                #return { id: result['tag']['id'], text: result['tag']['_data']['data']['text'] };
                id: tag["id"]
                text: tag["text"]
            )
            callback null, tags

    create: (data, callback) ->
        detector = new Detector()
        data.text = data.text.replace(/(\r\n|\n|\r)/gm,"");
        data.type = detector.detect(data.text)
        console.log(data.type)
        # construct a new instance of our class with the data, so it can
        # validate and extend it, etc., if we choose to do that in the future:
        node = db.createNode(data)
        tag = new Tag(node)
        
        # but we do the actual persisting with a Cypher query, so we can also
        # apply a label at the same time. (the save() method doesn't support
        # that, since it uses Neo4j's REST API, which doesn't support that.)
        console.log data
        query = [
            "CREATE (tag:Tag {data})"
            "RETURN tag"
        ].join("\n")
        params = data: data
        db.query query, params, (err, results) ->
            return callback(err)  if err
            tag = new Tag(results[0]["tag"])
            callback null, tag

        return data
 

module.exports = Tag