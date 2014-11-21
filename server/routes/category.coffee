express 	= require 'express'
router 		= express.Router()
categories	= require '../controllers/categories'
guides 		= require '../controllers/guides'  


# Routes

router.get "/category/new", categories.get_new
router.post "/category/new", categories.post_new
router.get "/category/:id", categories.get

router.get "/category/:id/guide/new", guides.get_new
router.post "/category/:id/guide/new", guides.post_new

module.exports = router