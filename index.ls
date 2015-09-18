#!/usr/bin/env lsc
require! {
  fs
  async
  split
  request
  ndjson: json
  through2: through
  'tool-stream': tool
  'bionode-ncbi': ncbi
  'stdout-stream': stdout
  'concat-stream': cat
  child_process: { exec }
}

pipeline do
  ncbi.search \genome 'rodentia or arthropoda'
  ncbi.expand \assembly
  ncbi.expand \tax

# Helpers
function stream f
  through.obj (@data, @enc, @next) -> f.call @

function serialize
  stream ->
    if typeof @data != 'string'
      @data = "#{JSON.stringify(@data)}\n"
    @push @data
    @next!

function pipeline ...args
  input = args.0
  for i from 1 til args.length
    if typeof args[i] == 'string'
      output = stream ->
        cmd = "echo \'#{JSON.stringify(@data)}\' | #{args[i]}"
        err, stdout, stderr, <~ exec cmd
        @push stdout
        @next!
    else
      output = args[i]
    input = input.pipe output
  input.pipe serialize! .pipe stdout
