{ Readable, PassThrough } = require 'stream'
_ = require 'lodash'

# A multisource stream is a readable stream.
# It can be piped to from any offset via the method .from() that returns a writable source.
module.exports = class Multisource extends Readable
  constructor: (options) ->
    super options

    @offset = 0
    @_readables = []
    @_aheads = []
    @_reading = true

  # Called when we need to read some data from the stream.
  _read: (size) =>
    # TODO: take account of size parameter.
    # Maybe as an additional argument to readSource?
    @_reading = true

    # As we are possibly going to read many sources, there is no need to track the return value of
    # readSource for every source. Instead, we compare the stream offset before and after the reading.
    prevOffset = @offset

    while @_reading and @_readables.length > 0
      source = @_readables.shift()
      @_readSource source

    if @offset isnt prevOffset
      @_readAheads()

  # Reads a source into the main stream's buffer.
  # Returns true if the stream's offset was raised.
  _readSource: (source) =>
    buffer = source.stream.read()

    # The source has no data available.
    return false if buffer is null

    delta = @offset - source.offset
    if delta > buffer.length
      # The source's buffer doesn't cross the stream's offset.
      # We empty its buffer and increment its offset.
      source.offset += buffer.length
      return false
    else
      if delta is 0
        # The source's offset is at the same spot as the stream's offset.
        # We directly push its buffer into the stream's buffer.
        @_reading = @push buffer
      else
        # The source's buffer crosses the stream's offset.
        # We push the slice that is ahead of the stream's offset.
        slice = buffer[delta..]
        @_reading = @push slice

      source.offset += buffer.length
      @offset = source.offset
      return true

  # Reads the source if the stream is reading, otherwise pushes it into the readable sources list.
  # Returns true if the stream's offset was raised.
  _maybeReadSource: (source) ->
    if @_reading
      return @_readSource source
    else
      @_readables.push source
      return false

  # Reads sources that are not ahead of the main stream anymore and removes them from the ahead sources list.
  _readAheads: =>
    while @_aheads.length > 0 and @_aheads[0].offset <= @offset
      source = @_aheads.shift()
      @_maybeReadSource source

  # Returns a new source that writes to the main stream from an offset.
  from: (offset, options) =>
    source =
      stream: new PassThrough options
      offset: offset

    if source.offset > @offset
      # The source is ahead of the main stream.
      # We insert it in the ahead sources list while maintaining order by offset.
      i = _.sortedIndex @_aheads, source, 'offset'
      @_aheads.splice i, 0, source

    source.stream.on 'readable', =>
      if source.offset <= @offset
        oldOffset = source.offset
        readable = @_maybeReadSource source
        if readable
          @_readAheads()

    return source.stream

  # Ends the stream
  end: ->
    @push null
