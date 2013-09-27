{ Duplex } = require 'stream'

# A source is a duplex stream that only outputs its input.
module.exports = class Source extends Duplex
  constructor: (options) ->
    super options

    @_writing = true

  _read: (size) ->
    if not @_writing
      @_writing = true
      @_writingCallback()

  _write: (chunk, encoding, callback) ->
    @_writing = @push chunk
    if not @_writing
      @_writingCallback = callback
    else
      callback()
