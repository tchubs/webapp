coffee = require("coffee-script")
express = require("express")
jade = require("jade")
lactate = require("lactate")
nconf = require("nconf")
https = require("https")
qs = require("querystring")

marketing = require("./marketing.json")
npm       = require("./package.json")

require "./configure"

isProductionMode = ->
  switch process.env.NODE_ENV or "local"
    when "local"
      false
    else
      true

app = module.exports = express()

app.set "views", "#{__dirname}/views"
app.set "view engine", "jade"
app.set "view options", layout: false

app.use express.logger()

# Serve out of dist or generated, depending upon the environment.
folder = "#{if isProductionMode() then 'dist' else 'generated'}"
app.use "/font", lactate.static("#{__dirname}/#{folder}/img", "max age": "one week")
app.use lactate.static "#{__dirname}/#{folder}", "max age": "one week"

app.use express.cookieParser()
app.use express.bodyParser()

app.use app.router

app.use express.errorHandler()

# Convenience for allowing CORS on routes - GET only
app.all '*', (req, res, next) ->
  res.header 'Access-Control-Allow-Origin', '*'
  res.header 'Access-Control-Allow-Methods', 'GET, OPTIONS'
  res.header 'Access-Control-Allow-Headers', 'Content-Type'
  next()

# Forward savvyparrot.herokuapp.com to www.savvyparrot.com
# Notice that we use HTTP status 301 Moved Permanently (best for SEO purposes).
app.get "/*", (req, res, next) ->
    if req.headers.host.match(/^savvyparrot.herokuapp.com/)
      next()
#      res.redirect("http://www.savvyparrot.com#{req.url}", 301)
    else
      next()

app.get "/*", (req, res, next) ->
  res.render "index",
    # Firefox appears to be having a problem with the minified JavaScript.
    css: if isProductionMode() then "/css/app.min.css?version=#{npm.version}" else "/css/app.css?version=#{npm.version}"
    js:  if isProductionMode() then "/js/app.min.js?version=#{npm.version}" else "/js/app.js?version=#{npm.version}"
    marketing: marketing
    npm: npm
