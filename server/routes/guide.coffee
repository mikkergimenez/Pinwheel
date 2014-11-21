express 		= require 'express'
router 			= express.Router()
guides 			= require '../controllers/guides'  
choicePoints 	= require '../controllers/choice_points'  

router.get "/guide/edit/:id", guides.get_edit
router.post "/guide/edit/:id", guides.post_edit
router.get "/guide/:id", guides.get

router.post "/guide/:id/node/new", choicePoints.post_new

router.post "/guide/addComment", (req, res) ->
    guide.addCommentToArticle req.param("_id"),
        person: req.param("person")
        comment: req.param("comment")
        created_at: new Date()
    , (error, docs) ->
        res.redirect "/guide/" + req.param("_id")

module.exports = router