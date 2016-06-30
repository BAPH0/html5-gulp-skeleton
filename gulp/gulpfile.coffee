
# ---------------------------------------------------------
#  setting
# ---------------------------------------------------------

# 開発
DIR_S = "src"
DIR_A = "assets"

# 納品
DIR_D = "../htdocs"

# 削除対象
DIR_C = [ "#{DIR_D}/**/*" ]

# パス管理
paths =
  html    : "#{DIR_S}/**/*.html"
  jade    : "#{DIR_S}/**/*.jade"
  css     : "#{DIR_S}/**/*.css"
  scss    : "#{DIR_S}/**/*.scss"
  coffee  : "#{DIR_S}/**/*.coffee"
  js      : "#{DIR_S}/**/*.js"
  json    : "#{DIR_S}/**/*.json"
  img     : [ "#{DIR_S}/**/*.png", "#{DIR_S}/**/*.jpg", "#{DIR_S}/**/*.gif" ]

# plugins
del          = require "del"
notifier     = require "node-notifier"
runSequence  = require "run-sequence"
gulp         = require "gulp"
$            = require("gulp-load-plugins")()


# ---------------------------------------------------------
#  helpers
# ---------------------------------------------------------

_plumber = (task) ->
  e = $.notify.onError title:"#{task} Error", message:"<%= error.message %>"
  return $.plumber errorHandler: e

_changed = (ext) ->
  if ext? then return $.changed DIR_D, { extension:".#{ext}" }
  else return $.changed DIR_D

_dest = -> return gulp.dest DIR_D

_trace = (str) ->
  d = new Date()
  hhmmss = "#{d.getHours()}:#{d.getMinutes()}:#{d.getSeconds()}"
  update = "[#{$.util.colors.gray(hhmmss)}]"
  console.log "#{update} #{$.util.colors.yellow(str)}"
  return


# ---------------------------------------------------------
#  individual tasks
# ---------------------------------------------------------

# clean

gulp.task "clean", (callback) -> del DIR_C, { force: true }, callback


# copy

gulp.task "copyhtml", ->
  gulp.src paths.html
    .pipe _changed()
    .pipe _plumber "copyhtml"
    .pipe _dest()

gulp.task "copycss", ->
  gulp.src paths.css
    .pipe _changed()
    .pipe _plumber "copycss"
    .pipe $.autoprefixer()
    .pipe _dest()

gulp.task "copyjs", ->
  gulp.src paths.js
    .pipe _changed()
    .pipe _plumber "copyjs"
    .pipe _dest()

gulp.task "copyjson", ["jsonlint"], ->
  gulp.src paths.json
    .pipe _changed()
    .pipe _plumber "copyjson"
    .pipe _dest()

gulp.task "copyimg", ->
  gulp.src paths.img
    .pipe _changed()
    .pipe _plumber "copyimg"
    .pipe _dest()


# html

gulp.task "jade", ->
  gulp.src paths.jade
    .pipe _plumber "jade"
    .pipe $.data -> require "./data.json"
    .pipe $.jade
      pretty: true
      basedir: "./#{DIR_S}"
    .pipe _dest()


# css

gulp.task "sass", ->
  gulp.src paths.scss
    .pipe _plumber "sass"
    .pipe $.sass
      outputStyle: "expanded"
    .pipe $.autoprefixer()
    .pipe _dest()


# js

gulp.task "coffee", ->
  gulp.src paths.coffee
    .pipe _plumber "coffee"
    .pipe $.coffee()
    .pipe _dest()

gulp.task "uglify", ->
  gulp.src paths.js
    .pipe _plumber "js"
    .pipe $.uglify()
    .pipe _dest()


# json

gulp.task "jsonlint", ->
  gulp.src paths.json
    .pipe _plumber "json"
    .pipe $.jsonlint()
    .pipe $.jsonlint.reporter()
    .pipe $.notify (file) -> if file.jsonlint.success then false else "jsonlint error"


# server

gulp.task "webserver", ->
  gulp.src DIR_D
    .pipe $.webserver
      livereload: true
      port: 50000
      open: true
      host: "localhost"
    .pipe $.notify '[run]: start local server. http://localhost:50000/'


# ---------------------------------------------------------
#  combination tasks
# ---------------------------------------------------------

gulp.task "tasksHtml", [ "copyhtml", "jade" ]
gulp.task "tasksCss", [ "copycss", "sass" ]
gulp.task "tasksJs", [ "copyjs", "coffee", "uglify" ]
gulp.task "tasksWatch", ->
  gulp.watch paths.html, [ "copyhtml" ]
  gulp.watch paths.css, [ "copycss" ]
  gulp.watch paths.js, [ "copyjs" ]
  gulp.watch paths.json, [ "copyjson" ]
  gulp.watch paths.img, [ "copyimg" ]
  gulp.watch paths.jade, [ "jade" ]
  gulp.watch paths.sass, [ "sass" ]
  gulp.watch paths.coffee, [ "coffee" ]


# call mainly

gulp.task "run", [ "webserver", "tasksWatch" ], ->
  _trace "--------------------------------"
  _trace "|        watch start...        |"
  _trace "--------------------------------"
  notifier.notify title: "gulp", message: "watch start..."

gulp.task "default", [ "clean" ], ->
  runSequence [ "copyjson" ], [ "tasksHtml", "tasksCss", "tasksJs", "copyimg" ], ->
    _trace "--------------------------------"
    _trace "|       build complete!!       |"
    _trace "--------------------------------"
    notifier.notify title: "gulp", message: "build complete!!"

