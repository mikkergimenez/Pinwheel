chai = require      "chai"
sinon = require     "sinon"
sinonChai = require "sinon-chai"

categories  = require '../controllers/categories'

chai.use sinonChai
chai.should()

resMock = {}


describe('Pinwheel Index route', ->

    requireIndex = (models) ->
        return require("../../server/controllers/categories")(models)

    callPinwheelIndexRoute = () ->
        index.get({}, response);
    
    beforeEach ->
        response = {}
        promiseMock = {}
        categoryMock = {}

        categoryMock.findAll = sinon.stub()
            .returns(promiseMock)

        promiseMock.then = sinon.spy()

        response.render = sinon.stub()
        response.send = sinon.stub()

        index = requireIndex()(categoryMock)

    it('Calls the render function', () ->

        callPinwheelIndexRoute()

        promiseMock.then.getCall(0).args[0]({})

        response.render.should.have.been.calledOnce
    )       
)



