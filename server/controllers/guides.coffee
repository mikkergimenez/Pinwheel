Guide = require("../models/guide.coffee")
guide = new Guide()

exports.get_edit = (req, res) ->
    guide.findWithNodesById req.params.id, (error, guide) ->
        console.log guide
        res.render "guide/edit.jade",
            locals:
                title: guide.title
                guide: guide
                category: guide.category
                nodes: guide.choice_points

exports.post_edit = (req, res) ->
    guide.findById req.params.id, (error, guide) ->
        res.render "guide/show.jade",
            locals:
                title: guide.title
                guide: guide
                category: guide.category

exports.get = (req, res) ->
    """
    Shows a guide, at /guide/:id
    """
    guide.findById req.params.id, (error, guide) ->
        res.render "guide/show.jade",
            locals:
                title: guide.title
                guide: guide
                category: guide.category

exports.get_new = (req, res) ->
    res.render "guide_new.jade",
        locals:
            title: "New Guide"

exports.post_new = (req, res) ->
    guide.create
        title: req.param("title")
        body: req.param("body")
        category: req.params.id
    ,   (error, docs) ->
        res.redirect "/category/"+req.params.id

