express 	= require 'express'
router 		= express.Router()
categories 	= "../../controllers/categories"

# GET home page.
#router.get '/', (req, res) ->
#  res.render('index', { title: 'Express' })

router.get "/", -> categories.index

module.exports = router
