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
          'default': ['$', 'SimpleModule', 'moment']
          amd: ['jquery', 'simple-module', 'moment-timezone']
          cjs: ['jquery', 'simple-module', 'moment-timezone']
          global:
            items: ['jQuery', 'SimpleModule', 'moment']
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
        files: ['lib/**/*.js', 'spec/**/*.js']
        tasks: 'jasmine'

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
            'vendor/bower/moment-timezone/moment-timezone.js'
            'vendor/bower/moment/locale/zh-cn.js'
          ]

  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-umd'

  grunt.registerTask 'default', ['sass', 'coffee', 'umd', 'jasmine', 'watch']
  grunt.registerTask 'test', ['sass', 'coffee', 'umd', 'jasmine']
