var gulp = require('gulp');
    coffee = require('gulp-coffee');
    concat = require('gulp-concat');
    gulpif = require('gulp-if');
    filelog = require('gulp-filelog');
    gutil = require('gulp-util');
    del = require('del');
    connect = require('gulp-connect');
    templateCache = require('gulp-angular-templatecache');
    imagemin = require('gulp-imagemin');
    rename = require('gulp-rename');
    flatten = require('gulp-flatten');
    sass = require('gulp-sass');
    merge = require('merge-stream');
    mainBowerFiles = require('main-bower-files');
    streamqueue = require('streamqueue');
    uglify = require('gulp-uglify');

gulp.task('clean', function(cb) {
  del.sync(['release']);
  cb()
});


gulp.task('list', function() {
  gulp.src(mainBowerFiles({filter: new RegExp('.js$')}))
    .pipe(filelog())
});

gulp.task('javascripts', function() {
  javascripts = gulp.src(mainBowerFiles({filter: new RegExp('.js$')}).concat([
        './bower_components/moment/locale/en-gb.js',
        './bower_components/lodash/dist/lodash.js',
        './bower_components/angular-google-maps/dist/angular-google-maps.js',
        './bower_components/webshim/js-webshim/dev/polyfiller.js',
        './src/javascripts/core/main.js.coffee', 
        './src/*/javascripts/main.js.coffee', 
        './src/*/main.js.coffee', 
        './src/core/javascripts/services/widget.js.coffee', 
        './src/core/javascripts/collections/base.js.coffee', 
        './src/*/javascripts/**/*', 
        './src/*/directives/**/*', 
        './src/*/models/**/*', 
        './src/*/services/**/*', 
        '!./**/*~',]))
    // .pipe(filelog())
    .pipe(gulpif(/.*coffee$/, coffee().on('error', function (e) {
      gutil.log(e)
      this.emit('end')
    })))
  templates = gulp.src('./src/*/templates/**/*.html')
    .pipe(flatten())
    .pipe(templateCache({module: 'BB'}))
  streamqueue({objectMode: true}, javascripts, templates)
    .pipe(concat('bookingbug-angular.js'))
    .pipe(uglify({mangle: false})).on('error', gutil.log)
    .pipe(gulp.dest('release'));
});

gulp.task('images', function() {
  return gulp.src('src/*/images/*')
    .pipe(imagemin())
    .pipe(flatten())
    .pipe(gulp.dest('release'));
});

gulp.task('shims', function() {
  return gulp.src('bower_components/webshim/js-webshim/minified/shims/*')
    .pipe(gulp.dest('release/shims'));
});

gulp.task('stylesheets', function() {
  css_stream = gulp.src(mainBowerFiles({filter: new RegExp('.css$')}))
  sass_stream = gulp.src('src/*/stylesheets/main.scss')
    .pipe(sass({errLogToConsole: true}))
    .pipe(flatten())
  streamqueue({objectMode: true}, css_stream, sass_stream)
    .pipe(concat('bookingbug-angular.css'))
    .pipe(gulp.dest('release'));
});

gulp.task('widget', function() {
  gulp.src('src/widget/stylesheets/main.scss')
    .pipe(sass({errLogToConsole: true}))
    .pipe(flatten())
    .pipe(concat('bookingbug-widget.css'))
    .pipe(gulp.dest('release'));
});

gulp.task('theme', function() {
  gulp.src('src/*/stylesheets/bb_light_theme.scss')
    .pipe(sass({errLogToConsole: true}))
    .pipe(flatten())
    .pipe(concat('bb-theme.css'))
    .pipe(gulp.dest('release'));
});

gulp.task('fonts', function() {
  gulp.src('src/*/fonts/*')
    .pipe(flatten())
    .pipe(gulp.dest('release/fonts'));
});


gulp.task('watch', function() {
  gulp.watch(['./src/**/*', '!./**/*~'], ['assets']);
});

gulp.task('webserver', ['assets'], function() {
  connect.server({
    root: ['release', 'examples', 'bower_components'],
    port: 8888
  });
});

gulp.task('assets', ['clean', 'javascripts', 'images', 'stylesheets','fonts', 'theme', 'shims', 'widget']);

gulp.task('default', ['assets', 'watch', 'webserver']);
