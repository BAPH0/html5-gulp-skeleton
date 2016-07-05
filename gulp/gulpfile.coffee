
# ---------------------------------------------------------
#  Settings for each project
# ---------------------------------------------------------

# port number of the localhost
PORT = 50000

# version of ECMAScript for typescript
ESV = "ES5"

# prefix outside the copy target
DCP = "_"

# the development source dir
DIR_S = "src"

# publishing dir
DIR_P = "../htdocs"

# delete the target dir
DIR_C = [
  "#{DIR_P}/**/*"
  "!#{DIR_P}/.htaccess"
  "!#{DIR_P}/.htpasswd"
  "!#{DIR_P}/index.php"
  "!#{DIR_P}/wordpress/**"
]

# root directory of tsify file
DIR_TSIFY = "assets/js"

# files name of tsify target (no extention string)
# please to note the #{DCP}
FILES_TSIFY = [ "#{DCP}bundle" ]


# ---------------------------------------------------------
#  Setting of gulp
# ---------------------------------------------------------

# paths array
PATHS =
  html    : "#{DIR_S}/**/*.html"
  jade    : "#{DIR_S}/**/*.jade"
  css     : "#{DIR_S}/**/*.css"
  sass    : "#{DIR_S}/**/*.{sass,scss}"
  coffee  : "#{DIR_S}/**/*.coffee"
  ts      : "#{DIR_S}/**/*.ts"
  js      : "#{DIR_S}/**/*.js"
  json    : "#{DIR_S}/**/*.json"
  img     : "#{DIR_S}/**/*.{png,jpg,gif}"
  other   : [
    "#{DIR_S}/**/*"
    "#{DIR_S}/**/.htaccess"
    "!#{DIR_S}/**/*.{html,jade,css,sass,scss,js,json,coffee,ts}"
    "!#{DIR_S}/**/img/**"
  ]

# plugins
fs           = require "fs"
del          = require "del"
notifier     = require "node-notifier"
browserify   = require "browserify"
runSequence  = require "run-sequence"
source       = require "vinyl-source-stream"
buffer       = require 'vinyl-buffer'
gulp         = require "gulp"
$            = require("gulp-load-plugins")()


# ---------------------------------------------------------
#  sugar functions
# ---------------------------------------------------------

_path = (ext) ->
  return [].concat PATHS[ext], [
    "!#{DIR_S}/**/#{DCP}*", "!#{DIR_S}/**/#{DCP}*/", "!#{DIR_S}/**/#{DCP}*/**" ]

_plm = (task) ->
  e = $.notify.onError title:"#{task} Error", message:"<%= error.message %>"
  return $.plumber errorHandler: e

_cgd = (ext) ->
  if ext? then return $.changed DIR_P, { extension:".#{ext}" }
  else return $.changed DIR_P

_dst = -> return gulp.dest DIR_P

_cpy = (src, task, callback) ->
  if callback? then gulp.src(src).pipe(_cgd()).pipe(_plm(task)).pipe(callback()).pipe(_dst())
  else gulp.src(src).pipe(_cgd()).pipe(_plm(task)).pipe(_dst())

_trc = (str) ->
  d = new Date()
  hhmmss = "#{d.getHours()}:#{d.getMinutes()}:#{d.getSeconds()}"
  update = "[#{$.util.colors.gray(hhmmss)}]"
  console.log "#{update} #{$.util.colors.yellow(str)}"
  return

_exist = (filepath, callback) ->
  if not filepath instanceof String then return
  if not callback instanceof Function or not callback then return
  fs.exists filepath, (exists) ->
    if exists then callback(exists) else _trc "File not exist: '#{filepath}'"
  return


# ---------------------------------------------------------
#  individual tasks
# ---------------------------------------------------------

# clean
gulp.task "clean", (callback) -> del DIR_C, { force: true }, callback

# copy
gulp.task "copyhtml", -> _cpy _path("html"), "copyhtml"
gulp.task "copycss", -> _cpy _path("css"), "copycss", $.autoprefixer
gulp.task "copyjs", -> _cpy _path("js"), "copyjs"
gulp.task "copyjson", ["jsonlint"], -> _cpy _path("json"), "copyjson"
gulp.task "copyimg", -> _cpy _path("img"), "copyimg"
gulp.task "copyother", -> _cpy _path("other"), "copyother"

# html
gulp.task "jade", ->
  gulp.src _path "jade"
    .pipe _plm "jade"
    .pipe $.data -> require "./data.json"
    .pipe $.jade
      pretty: true
      basedir: "./#{DIR_S}"
    .pipe _dst()

# css
gulp.task "sass", ->
  gulp.src _path "sass"
    .pipe _plm "sass"
    .pipe $.sass
      outputStyle: "expanded"
    .pipe $.autoprefixer()
    .pipe _dst()

# js
_tasksJs = [ "copyjs", "ts", "coffee", "uglify" ]
_tasksTsify = []
_projTsify = $.typescript.createProject
  target: "#{ESV}"
  removeComments: true
  sortOutput: true
  module: "commonjs"

_tsify = (filename) ->
  _taskname = "tsify: #{filename}.ts"
  _srcfile = "#{DIR_S}/#{DIR_TSIFY}/#{filename}.ts"
  _destdir = "#{DIR_P}/#{DIR_TSIFY}"
  _exist _srcfile, (exists) ->
    gulp.task _taskname, ->
      bs = browserify()
        .add _srcfile
        .plugin "tsify", _projTsify
        .bundle()
        .pipe _plm "tsify"
      bs
        .pipe source "#{filename}.js"
        .pipe buffer()
        .pipe gulp.dest _destdir
      bs
        .pipe source "#{filename}.min.js"
        .pipe buffer()
        .pipe $.uglify()
        .pipe gulp.dest _destdir
    _tasksTsify.push -> gulp.watch _srcfile, [ _taskname ]
    _tasksJs.push _taskname
    return
if FILES_TSIFY.length then for n in FILES_TSIFY then _tsify n

gulp.task "ts", ->
  gulp.src _path "ts"
    .pipe _plm "ts"
    .pipe $.typescript _projTsify
    .js
    .pipe _dst()

gulp.task "coffee", ->
  gulp.src _path "coffee"
    .pipe _plm "coffee"
    .pipe $.coffee()
    .pipe _dst()

gulp.task "uglify", ->
  gulp.src _path "js"
    .pipe _plm "js"
    .pipe $.uglify()
    .pipe _dst()

# json
gulp.task "jsonlint", ->
  gulp.src _path "json"
    .pipe _plm "json"
    .pipe $.jsonlint()
    .pipe $.jsonlint.reporter()
    .pipe $.notify (file) -> if file.jsonlint.success then false else "jsonlint error"

# server
gulp.task "webserver", ->
  gulp.src DIR_P
    .pipe $.webserver
      livereload: true
      port: PORT
      open: true
      host: "localhost"
    .pipe $.notify "[run]: start local server. http://localhost:#{PORT}/"


# ---------------------------------------------------------
#  combination tasks
# ---------------------------------------------------------

gulp.task "tasksJs", _tasksJs
gulp.task "tasksCss", [ "copycss", "sass" ]
gulp.task "tasksHtml", [ "jade", "copyhtml" ]
gulp.task "tasksWatch", ->
  gulp.watch _path("html"),   [ "copyhtml" ]
  gulp.watch _path("css"),    [ "copycss" ]
  gulp.watch _path("js"),     [ "copyjs" ]
  gulp.watch _path("json"),   [ "copyjson" ]
  gulp.watch _path("img"),    [ "copyimg" ]
  gulp.watch _path("img"),    [ "copyother" ]
  gulp.watch _path("jade"),   [ "jade" ]
  gulp.watch _path("sass"),   [ "sass" ]
  gulp.watch _path("coffee"), [ "coffee" ]
  gulp.watch _path("ts"),     [ "ts" ]
  if _tasksTsify.length then for task in _tasksTsify then task()

# call mainly

gulp.task "run", [ "webserver", "tasksWatch" ], ->
  _trc "jgggp     .ggggg     .gggg!      .gggggp      .ggggggggggggggg:     ..(gNMMMNNg,   jggg[       (gggp"
  _trc "dMMM#     dMMMMM    .MMMMt      .MMMMMMN      dMMMMMMMMMMMMMM#    .MMMMMMMMMMM#   .MMMM        MMMM]"
  _trc "JMMM#    JMMMMM#   .MMMMF      .MMMFMMMM-     `````jMMM#``````  .MMMMM9^`    _!   (MMM#       .MMMM`"
  _trc "(MMM#   .MM#dMM#   JMMMF      .MMM@ dMMM]          MMMMF       jMMMM'             MMMMF       dMMMF"
  _trc ",MMM#  .MMM^dMM#  .MMM@      .MMM#` JMMMb         .MMMM!      (MMMMt             .MMMMa&+++++&MMMM"
  _trc ",MMM# .MMMF dMM# .MMM#     `.MMM#`  ,MMMN     `   JMMM#       MMMM#              JMMMMMMMMMMMMMMM#"
  _trc ".MMM# dMMF  dMM#.MMMM`     .MMMMNggggMMMM_       .MMMM%      .MMMM#             .MMMMY7777777MMMMF"
  _trc ".MMM@(MM#   dMM#(MMM!     .MMMMMMMMMMMMMM]       .MMMM`    `  MMMMM,    `       .MMMM       .MMMM:"
  _trc " MMMNMM#`   dMMMMMM^     .MMMM$      MMMMb   `   dMMMF        ,MMMMMa,.  ` ..   dMMMF       JMMM#"
  _trc " MMMMMM'    dMMMMM%     .MMMMF       dMMM#      .MMMM          .WMMMMMMMMMMMF  .MMMM>      .MMMM%"
  _trc " MMMMM^     ?MMMMt     .MMMMD        ?MMMM      JMMMB             ?'MMMMMMMY'  ?MMME       ,MMMM`"
  notifier.notify title: "gulp", message: "watch start..."

gulp.task "default", [ "clean" ], ->
  runSequence [ "copyjson" ], [ "tasksHtml", "tasksCss", "tasksJs", "copyimg", "copyother" ], ->
    _trc "    .gNNNNNNNNm+.     .NNNK_      .NNNK_  .dNNmI   .NNNm_         .gNNNNNNNNNga..       jNNNR"
    _trc "   .dMMMMBWHMMMMN+    jMMM#       jMMM#   .MMM#>   jMMM#          ,MMMMHBWHMMMMMNx     .WMM#3"
    _trc "   .MMM#>   .WMMM@   .MMM#C      .MMM#C   JMMM#   .WMM#3          jMMM#     (TMMMNs    ,MMM#`"
    _trc "   JMMM#    .dMM#C   ,MMM#`      (MMM#~  .dMM#C   ,MMM#~         .NMM#C       wMMM#-   JMM#$"
    _trc "  .dMMMNggggMMMY!   .dMMMD      .dMMMD   ,MMM#~  .dMMME          (MMM#_       (MMM#>  .dMM#`"
    _trc "  ,MMMMMMMMMMNm.    .MMM#>      .MMM#>   jMMME   .MMM#>         .dMMMD        (MMM#~  .MM#$"
    _trc "  dMMME   _7MMMNx   (MMM#       (MMM#   .NMM#>   JMMM#`         .MMM#>       .MMMM8   (MM@`"
    _trc " .MMM#>    .WMMM@   dMMM#      .MMM#>   (MMM#`  .dMMND          (MMM#      .(NMMM@`    ~_`"
    _trc " JMMM#....(gMMM@!   (MMMNm-...gMMM#=   .dMMMD   ,MMMN&.......  .WMMN$....(gNMMMM$   .&NNNp"
    _trc ".dMMMMMMMMMMM#Y`     ?MMMMMMMMMMM8!    .MMM#:   jMMMMMMMMMMM#  ,MMMMMMMMMMMMMB=`    (MMMM@"
    _trc ".7TTTTTTY7=?`          ?TTHH9YY7`      (TTT3    OTTTTTTTTTTYC  (7TTTTTTY777~`        ?W9=`"
    notifier.notify title: "gulp", message: "build complete!!"

