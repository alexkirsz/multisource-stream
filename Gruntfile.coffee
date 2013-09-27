module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    watch:
      lib:
        files: ['src/lib/**/*.coffee']
        tasks: ['coffee:lib']
        options:
          delta: true
          spawn: false

      test:
        files: ['src/test/**/*.coffee']
        tasks: ['coffee:test']
        options:
          delta: true
          spawn: false

    coffee:
      lib:
        expand: true
        cwd: 'src/'
        src: 'lib/**/*.coffee'
        dest: '.'
        ext: '.js'

      test:
        expand: true
        cwd: 'src/'
        src: 'test/**/*.coffee'
        dest: '.'
        ext: '.js'

    clean: ['lib', 'test']

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-clean'

  grunt.registerTask 'default', ['clean', 'coffee:lib', 'coffee:test']

  grunt.event.on 'watch', (action, filepath, target) ->
    { options, tasks } = grunt.config ['watch', target, 'options']
    return if not options?.delta

    for task in tasks
      [task, target] = task.split ':'
      # Compile only changed files
      { src, dest, cwd, ext, options } = grunt.config [task, target]
      mapping = grunt.file.expandMapping src, dest, { cwd, ext }
      for { src: srcFiles, dest: destFile } in mapping when filepath in srcFiles 
        fileMapping = {}
        fileMapping[destFile] = srcFiles
        grunt.config [task, target],
          files: fileMapping
          options: options
        break
