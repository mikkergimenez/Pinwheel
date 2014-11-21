# user.coffee
# User model logic.

neo4j = require("node-neo4j")

db = new neo4j.GraphDatabase(process.env["NEO4J_URL"] or process.env["GRAPHENEDB_URL"] or "http://localhost:7474")

Function::define = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc

# private constructor:
#User = module.exports = User = (_node) ->
class User

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
        
        # use a Cypher query to delete both this user and his/her following
        # relationships in one transaction and one network request:
        # (note that this'll still fail if there are any relationships attached
        # of any other types, which is good because we don't expect any.)
        query = [
            "MATCH (user:User)"
            "WHERE ID(user) = {userId}"
            "DELETE user"
            "WITH user"
            "MATCH (user) -[rel:follows]- (other)"
            "DELETE rel"
        ].join("\n")
        params = userId: @id
        db.query query, params, (err) ->
            callback err

    follow:  (other, callback) ->
        @_node.createRelationshipTo other._node, "follows", {}, (err, rel) ->
            callback err
        
    unfollow: (other, callback) ->
        query = [
            "MATCH (user:User) -[rel:follows]-> (other:User)"
            "WHERE ID(user) = {userId} AND ID(other) = {otherId}"
            "DELETE rel"
        ].join("\n")
        params =
            userId: @id
            otherId: other.id

        db.query query, params, (err) ->
            callback err

    # calls callback w/ (err, following, others) where following is an array of
    # users this user follows, and others is all other users minus him/herself.
    getFollowingAndOthers: (callback) ->
    
        # query all users and whether we follow each one or not:
        # COUNT(rel) is a hack for 1 or 0
        query = [
            "MATCH (user:User), (other:User)"
            "OPTIONAL MATCH (user) -[rel:follows]-> (other)"
            "WHERE ID(user) = {userId}"
            "RETURN other, COUNT(rel)"
        ].join("\n")
        params = userId: @id
        user = this
        db.query query, params, (err, results) ->
            return callback(err)  if err
            following = []
            others = []
            i = 0

            while i < results.length
                other = new User(results[i]["other"])
                follows = results[i]["COUNT(rel)"]
                if user.id is other.id
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
            return callback(err)  if err
            callback null, new User(node)

    findAll: (callback) ->
        query = [
            "MATCH (user:User)"
            "RETURN user"
        ].join("\n")
        db.query query, null, (err, results) ->
            return callback(err)  if err
            users = results.map((result) ->
                user = new User(result["user"])
                
                #return { id: result['user']['id'], text: result['user']['_data']['data']['text'] };
                id: user["id"]
                text: user["text"]
            )
            callback null, users

    create: (data, callback) ->
        detector = new Detector()
        data.text = data.text.replace(/(\r\n|\n|\r)/gm,"");
        data.type = detector.detect(data.text)
        console.log(data.type)
        # construct a new instance of our class with the data, so it can
        # validate and extend it, etc., if we choose to do that in the future:
        node = db.createNode(data)
        user = new User(node)
        
        # but we do the actual persisting with a Cypher query, so we can also
        # apply a label at the same time. (the save() method doesn't support
        # that, since it uses Neo4j's REST API, which doesn't support that.)
        console.log data
        query = [
            "CREATE (user:User {data})"
            "RETURN user"
        ].join("\n")
        params = data: data
        db.query query, params, (err, results) ->
            return callback(err)  if err
            user = new User(results[0]["user"])
            callback null, user

        return data
 

module.exports = User