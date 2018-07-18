module.exports = (grunt) ->

  grunt.initConfig

    pkg: grunt.file.readJSON 'package.json'

    sass:
      styles:
        options:
          bundleExec: true
          style: 'expanded'
          sourcemap: 'none'
        files:
          'styles/calendar.css': 'styles/calendar.scss'

    coffee:
      src:
        options:
          bare: true
        files:
          'lib/calendar.js': 'src/calendar.coffee'
      spec:
        files:
          'spec/calendar-spec.js': 'spec/calendar-spec.coffee'

    umd:
      all:
        src: 'lib/calendar.js'
        template: 'umd.hbs'
        amdModuleId: 'simple-calendar'
        objectToExport: 'calendar'
        globalAlias: 'calendar'
        deps:
          'default': ['$', 'SimpleModule', 'SimpleDragdrop', 'moment']
          amd: ['jquery', 'simple-module', 'simple-dragdrop', 'moment-timezone']
          cjs: ['jquery', 'simple-module', 'simple-dragdrop', 'moment-timezone']
          global:
            items: ['jQuery', 'SimpleModule', 'simple.dragdrop','moment']
            prefix: ''

    watch:
      styles:
        files: ['styles/*.scss']
        tasks: ['sass']
      spec:
        files: ['spec/**/*.coffee']
        tasks: ['coffee:spec']
      src:
        files: ['src/**/*.coffee']
        tasks: ['coffee:src', 'umd']

    jasmine:
      test:
        src: ['lib/**/*.js']
        options:
          outfile: 'spec/index.html'
          styles: 'styles/calendar.css'
          specs: 'spec/calendar-spec.js'
          vendor: [
            'vendor/bower/jquery/dist/jquery.min.js'
            'vendor/bower/simple-module/lib/module.js'
            'vendor/bower/moment/moment.js'
            'vendor/bower/moment-timezone/builds/moment-timezone-with-data.min.js'
            'vendor/bower/moment/locale/zh-cn.js'
            'vendor/bower/simple-dragdrop/lib/dragdrop.js'
          ]

  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-umd'

  grunt.registerTask 'default', ['sass', 'coffee', 'umd', 'watch']
  grunt.registerTask 'test', ['sass', 'coffee', 'umd', 'jasmine']
