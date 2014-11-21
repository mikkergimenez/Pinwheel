ChoicePoint = require("../models/choice_point.coffee")
choicePoint = new ChoicePoint()


exports.post_new = (req, res) ->
    choicePoint.create
        title: req.param("title")
        website: req.param("website")
        body: req.param("body")
        guide: req.params.id
    ,   (error, docs) ->
        res.redirect "/guide/"+req.params.id

