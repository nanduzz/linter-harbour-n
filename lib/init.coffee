{CompositeDisposable} = require 'atom'
path = require 'path'
fs = require 'fs'
helpers = require 'atom-linter'

module.exports =
  config:
    hbmk2ExecutablePath:
      type: 'string'
      title: 'Path to hbmk2 file'
      default: 'c:\\hb30\\bin\\hbmk2.exe'
    hbmk2Options:
      type: 'string'
      title: 'Options to compile separated by semicolon(;)'
      default: '-n;-s;-w3;-es1;-q0'
    hbmk2Includes:
      type: 'string'
      title: 'Includes to compile separated by semicolon(;)'
      default: '.\\;.\\include'

  activate: ->
    console.log 'Linter Harbour N Active'
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-harbour-n.hbmk2ExecutablePath',
      (newValue) =>
        @hbmk2ExecutablePath = newValue
    @subscriptions.add atom.config.observe 'linter-harbour-n.hbmk2Options',
      (newValue) =>
        @hbmk2Options = newValue
    @subscriptions.add atom.config.observe 'linter-harbour-n.hbmk2Includes',
      (newValue) =>
        @hbmk2Includes = newValue

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    grammarScopes: ['source.harbour']
    scope: 'file'
    lintOnFly: false       # Only lint on save
    lint: (textEditor) =>
      filePath = textEditor.getPath()

      # Split strint into array
      hbmk2Includes = @hbmk2Includes.split ';'
      hbmk2Options  = @hbmk2Options.split ';'

      # Add -i for header's path
      hbmk2Includes[x] = "-i" + hbmk2Includes[x] for include, x in hbmk2Includes

      # Arguments to hbmk2
      args = [filePath]
      args = args.concat hbmk2Options
      args = args.concat hbmk2Includes

      helpers.exec(@hbmk2ExecutablePath, args, {stream: 'stderr'})
        .then (val) => return @parse(val, textEditor)

  parse: (harbourOutput, textEditor) ->
    # Regex to match the error/warning line
    errRegex = /(\w+\.prg)\((\d+)\) (\w+) (.+)/ # criado por mim
    # Split into lines
    lines = harbourOutput.split /\r?\n/
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
