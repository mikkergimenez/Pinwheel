# todo.js
# Item model logic.

neo4j = require("neo4j")

db = new neo4j.GraphDatabase(process.env["NEO4J_URL"] or process.env["GRAPHENEDB_URL"] or "http://localhost:7474")

Function::define = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc

# private constructor:
#Item = module.exports = Item = (_node) ->
class Item

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
        
        # use a Cypher query to delete both this todo and his/her following
        # relationships in one transaction and one network request:
        # (note that this'll still fail if there are any relationships attached
        # of any other types, which is good because we don't expect any.)
        query = [
            "MATCH (todo:Item)"
            "WHERE ID(todo) = {todoId}"
            "DELETE todo"
            "WITH todo"
            "MATCH (todo) -[rel:follows]- (other)"
            "DELETE rel"
        ].join("\n")
        params = todoId: @id
        db.query query, params, (err) ->
            callback err

    follow:  (other, callback) ->
        @_node.createRelationshipTo other._node, "follows", {}, (err, rel) ->
            callback err
        
    unfollow: (other, callback) ->
        query = [
            "MATCH (todo:Item) -[rel:follows]-> (other:Item)"
            "WHERE ID(todo) = {todoId} AND ID(other) = {otherId}"
            "DELETE rel"
        ].join("\n")
        params =
            todoId: @id
            otherId: other.id

        db.query query, params, (err) ->
            callback err

    # calls callback w/ (err, following, others) where following is an array of
    # todos this todo follows, and others is all other todos minus him/herself.
    getFollowingAndOthers: (callback) ->
    
        # query all todos and whether we follow each one or not:
        # COUNT(rel) is a hack for 1 or 0
        query = [
            "MATCH (todo:Item), (other:Item)"
            "OPTIONAL MATCH (todo) -[rel:follows]-> (other)"
            "WHERE ID(todo) = {todoId}"
            "RETURN other, COUNT(rel)"
        ].join("\n")
        params = todoId: @id
        todo = this
        db.query query, params, (err, results) ->
            return callback(err)  if err
            following = []
            others = []
            i = 0

            while i < results.length
                other = new Item(results[i]["other"])
                follows = results[i]["COUNT(rel)"]
                if todo.id is other.id
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
            callback null, new Item(node)

    findAll: (callback) ->
        query = [
            "MATCH (todo:Item)"
            "RETURN todo"
        ].join("\n")
        db.query query, null, (err, results) ->
            return callback(err)  if err
            todos = results.map((result) ->
                todo = new Item(result["todo"])
                
                #return { id: result['todo']['id'], text: result['todo']['_data']['data']['text'] };
                id: todo["id"]
                text: todo["text"]
            )
            callback null, todos

    create: (data, callback) ->
        detector = new Detector()
        data.text = data.text.replace(/(\r\n|\n|\r)/gm,"");
        data.type = detector.detect(data.text)
        console.log(data.type)
        # construct a new instance of our class with the data, so it can
        # validate and extend it, etc., if we choose to do that in the future:
        node = db.createNode(data)
        todo = new Item(node)
        
        # but we do the actual persisting with a Cypher query, so we can also
        # apply a label at the same time. (the save() method doesn't support
        # that, since it uses Neo4j's REST API, which doesn't support that.)
        console.log data
        query = [
            "CREATE (todo:Item {data})"
            "RETURN todo"
        ].join("\n")
        params = data: data
        db.query query, params, (err, results) ->
            return callback(err)  if err
            todo = new Item(results[0]["todo"])
            callback null, todo

        return data
 

module.exports = Item