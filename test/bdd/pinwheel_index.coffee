'use strict'

# Instantiate the app module to start the web server.
require '../../server/app'

# Use chai and chai as promised for my assertions
chai = require "chai"
chaiAsPromised = require "chai-as-promised"
chai.use(chaiAsPromised)

chai.should()

# Use the wd library for webdriver
wd = require 'wd'

# Link chai-as-promised and wd promise chaining
chaiAsPromised.transferPromiseness = wd.transferPromiseness

# Browser driver
browser = wd.promiseChainRemote()

describe 'Pinwheel Index', () ->
	@timeout(6000)

	before (done) ->
		browser.init(
			browserName: 'firefox'
		).then () ->
			done()

	beforeEach (done) ->
		browser.get('http://localhost:3000/')
		.then () ->
			done()

	after (done) ->
		browser.quit()
			.then () ->
				done()

	it 'displays a number of categories on the index', (done) ->
		browser.elementsByCssSelector '#categories'
			.should.eventually.have.length.above(0).notify(done)
