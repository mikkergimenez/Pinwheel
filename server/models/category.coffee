# category.js
# Category model logic.

neo4j = require("neo4j")

db = new neo4j.GraphDatabase(process.env["NEO4J_URL"] or process.env["GRAPHENEDB_URL"] or "http://localhost:7474")

Function::define = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc

# private constructor:
#Category = module.exports = Category = (_node) ->
class Category

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
        
        # use a Cypher query to delete both this category and his/her following
        # relationships in one transaction and one network request:
        # (note that this'll still fail if there are any relationships attached
        # of any other types, which is good because we don't expect any.)
        query = [
            "MATCH (category:Category)"
            "WHERE ID(category) = {categoryId}"
            "DELETE category"
            "WITH category"
            "MATCH (category) -[rel:follows]- (other)"
            "DELETE rel"
        ].join("\n")
        params = categoryId: @id
        db.query query, params, (err) ->
            callback err

    follow:  (other, callback) ->
        @_node.createRelationshipTo other._node, "follows", {}, (err, rel) ->
            callback err
        
    unfollow: (other, callback) ->
        query = [
            "MATCH (category:Category) -[rel:follows]-> (other:Category)"
            "WHERE ID(category) = {categoryId} AND ID(other) = {otherId}"
            "DELETE rel"
        ].join("\n")
        params =
            categoryId: @id
            otherId: other.id

        db.query query, params, (err) ->
            callback err

    # calls callback w/ (err, following, others) where following is an array of
    # categories this category follows, and others is all other categories minus him/herself.
    getFollowingAndOthers: (callback) ->
    
        # query all categories and whether we follow each one or not:
        # COUNT(rel) is a hack for 1 or 0
        query = [
            "MATCH (category:Category), (other:Category)"
            "OPTIONAL MATCH (category) -[rel:follows]-> (other)"
            "WHERE ID(category) = {categoryId}"
            "RETURN other, COUNT(rel)"
        ].join("\n")
        params = categoryId: @id
        category = this
        db.query query, params, (err, results) ->
            return callback(err)  if err
            following = []
            others = []
            i = 0

            while i < results.length
                other = new Category(results[i]["other"])
                follows = results[i]["COUNT(rel)"]
                if category.id is other.id
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
            callback null, new Category(node)

    findAll: (callback) ->
        query = [
            "MATCH (category:Category)"
            "RETURN category"
        ].join("\n")
        db.query query, null, (err, results) ->
            return callback(err)  if err
            categories = results.map((result) ->
                category = new Category(result["category"])
                
                #return { id: result['category']['id'], text: result['category']['_data']['data']['text'] };
                
                _id: category["_id"]
                title: category["title"]
                body: category["body"]

            )
            callback null, categories

    create: (data, callback) ->
        # construct a new instance of our class with the data, so it can
        # validate and extend it, etc., if we choose to do that in the future:
        node = db.createNode(data)
        category = new Category(node)
        
        # but we do the actual persisting with a Cypher query, so we can also
        # apply a label at the same time. (the save() method doesn't support
        # that, since it uses Neo4j's REST API, which doesn't support that.)
        query = [
            "CREATE (category:Category {data})"
            "RETURN category"
        ].join("\n")
        params = data: data
        db.query query, params, (err, results) ->
            return callback(err)  if err
            category = new Category(results[0]["category"])
            callback null, category

        return data
 

module.exports = Category