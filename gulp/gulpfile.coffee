
# ---------------------------------------------------------
#  setting
# ---------------------------------------------------------

# src dir
DIR_S = "src"

# publish dir
DIR_P = "../htdocs"

# clean dir
DIR_C = [
  "#{DIR_P}/**/*"
  "!#{DIR_P}/.htaccess"
  "!#{DIR_P}/.htpasswd"
  "!#{DIR_P}/index.php"
  "!#{DIR_P}/wordpress/**"
]

# paths array
PA =
  html    : "#{DIR_S}/**/*.html"
  jade    : "#{DIR_S}/**/*.jade"
  css     : "#{DIR_S}/**/*.css"
  sass    : "#{DIR_S}/**/*.{sass,scss}"
  coffee  : "#{DIR_S}/**/*.coffee"
  js      : "#{DIR_S}/**/*.js"
  json    : "#{DIR_S}/**/*.json"
  img     : "#{DIR_S}/**/*.{png,jpg,gif}"
  other   : "#{DIR_S}/**/*.{htaccess,htpasswd}"

# plugins
del          = require "del"
notifier     = require "node-notifier"
runSequence  = require "run-sequence"
gulp         = require "gulp"
$            = require("gulp-load-plugins")()


# ---------------------------------------------------------
#  sugar functions
# ---------------------------------------------------------

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

# ---------------------------------------------------------
#  individual tasks
# ---------------------------------------------------------

# clean
gulp.task "clean", (callback) -> del DIR_C, { force: true }, callback

# copy
gulp.task "copyhtml", -> _cpy PA.html, "copyhtml"
gulp.task "copycss", -> _cpy PA.css, "copycss", $.autoprefixer
gulp.task "copyjs", -> _cpy PA.js, "copyjs"
gulp.task "copyjson", ["jsonlint"], -> _cpy PA.json, "copyjson"
gulp.task "copyimg", -> _cpy PA.img, "copyimg"

# html
gulp.task "jade", ->
  gulp.src PA.jade
    .pipe _plm "jade"
    .pipe $.data -> require "./data.json"
    .pipe $.jade
      pretty: true
      basedir: "./#{DIR_S}"
    .pipe _dst()

# css
gulp.task "sass", ->
  gulp.src PA.sass
    .pipe _plm "sass"
    .pipe $.sass
      outputStyle: "expanded"
    .pipe $.autoprefixer()
    .pipe _dst()

# js
gulp.task "coffee", ->
  gulp.src PA.coffee
    .pipe _plm "coffee"
    .pipe $.coffee()
    .pipe _dst()

gulp.task "uglify", ->
  gulp.src PA.js
    .pipe _plm "js"
    .pipe $.uglify()
    .pipe _dst()

# json
gulp.task "jsonlint", ->
  gulp.src PA.json
    .pipe _plm "json"
    .pipe $.jsonlint()
    .pipe $.jsonlint.reporter()
    .pipe $.notify (file) -> if file.jsonlint.success then false else "jsonlint error"

# server
gulp.task "webserver", ->
  gulp.src DIR_P
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
  gulp.watch PA.html, [ "copyhtml" ]
  gulp.watch PA.css, [ "copycss" ]
  gulp.watch PA.js, [ "copyjs" ]
  gulp.watch PA.json, [ "copyjson" ]
  gulp.watch PA.img, [ "copyimg" ]
  gulp.watch PA.jade, [ "jade" ]
  gulp.watch PA.sass, [ "sass" ]
  gulp.watch PA.coffee, [ "coffee" ]

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
  runSequence [ "copyjson" ], [ "tasksHtml", "tasksCss", "tasksJs", "copyimg" ], ->
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

