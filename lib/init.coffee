{BufferedProcess, CompositeDisposable} = require 'atom'
path = require 'path'
helpers = require 'atom-linter'

module.exports =
  config:
    hbmk2ExecutablePath:
      type: 'string'
      title: 'Path to hbmk2 file'
      default: 'C:\\Program Files (x86)\\SG Sistemas\\Projeto SGTrainee\\harbour\\bin\\hbmk2.exe'

  activate: ->
    console.log 'Linter Harbour N Active'
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-harbour-n.hbmk2ExecutablePath',
      (newValue) =>
        @hbmk2ExecutablePath = newValue
  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    grammarScopes: ['source.harbour']
    scope: 'file'
    lintOnFly: false       # Only lint on save
    lint: (textEditor) =>
      filePath = textEditor.getPath()
      wd = path.dirname filePath
      # Use the text editor's working directory as the classpath.
      #  TODO: Make the classpath user configurable.
      messages = []
      #args = ['-Xlint:all', '-n -s -w3 -es1 -q0', wd, filePath]
      args = [filePath, '-n', '-s','-w3', '-es1', '-q0']
      helpers.exec(@hbmk2ExecutablePath, args, {stream: 'stderr'})
        .then (val) => return @parse(val, textEditor)

  parse: (javacOutput, textEditor) ->
    # Regex to match the error/warning line
    errRegex = /(\w+\.prg)\((\d+)\) (\w+) (.+)/ # criado por mim
    # Split into lines
    lines = javacOutput.split /\r?\n/
    messages = []
    for line in lines
      if line.match errRegex
        [file, lineNum, type, mess] = line.match(errRegex)[1..4]
        if( type == "Warning")
          type = "warning"
        else
          type = "error"
        file = textEditor.getPath()
        messages.push
          type: type       # Should be "error" or "warning"
          text: mess       # The error message
          filePath: file   # Full path to file
          range: [[lineNum - 1, 0], [lineNum - 1, 0]]
    return messages
