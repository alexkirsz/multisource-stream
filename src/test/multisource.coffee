crypto = require 'crypto'
should = require 'should'
_ = require 'lodash'
Multisource = require '../lib/multisource'

describe 'Writing parts of data to the sources of a Multisource', ->
  it 'should return the input data recomposed (random)', ->
    dataLength = 1000000
    multi = new Multisource highWaterMark: dataLength
    data = crypto.randomBytes dataLength

    parts = []
    offset = 0
    while offset < dataLength
      start = offset - (Math.floor Math.random() * dataLength / 100)
      start = 0 if start < 0
      end = offset + (Math.floor Math.random() * dataLength / 10000)
      end = dataLength if end > dataLength
      parts.push [start, end]

      offset = end if end > offset

    parts = _.shuffle parts
    sources = []
    for part in parts
      source =
        offset: 0
        length: part[1] - part[0]
        data: data[part[0]...part[1]]
        stream: multi.from part[0], highWaterMark: dataLength
      sources.push source

    while multi.offset < dataLength
      sourceId = Math.floor Math.random() * sources.length
      source = sources[sourceId]
      bytesToWrite = Math.ceil Math.random() * source.length
      bytesToWrite = source.length - source.offset if bytesToWrite > source.length - source.offset
      chunk = source.data[source.offset...source.offset + bytesToWrite]
      source.offset += bytesToWrite
      sources.splice sourceId, 1 if source.offset is source.length
      source.stream.write chunk

    multi.read().toString().should.equal data.toString()
