module.exports = (category) ->
    'use strict'

    if not category?
        Category = require("../models/category.coffee")
        category = new Category()

    if not guide?
        Guide = require("../models/guide.coffee")
        guide = new Guide()

    return {
        index: (req, res) ->
    # res.render('index', { title: 'Express' })
            category.findAll((error, docs) ->
                res.render('index.jade'
                    locals:
                        title: 'Categories'
                        categories: docs
                )
            )

        get: (req, res) ->
            category.findById req.params.id, (error, category) ->
                guide.findByCategoryId req.params.id, (error, guide) ->
                    guide = [] unless guide
                    res.render "category_show.jade",
                        locals:
                            title: category.title
                            category: category
                            guides: guide

        get_new: (req, res) ->
            res.render "category_new.jade",
                locals:
                    title: "New Category"

        post_new: (req, res) ->
            category.create
                title: req.param("title")
                body: req.param("body")
            ,   (error, docs) ->
                res.redirect "/"
    }
    