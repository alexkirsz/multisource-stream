crypto = require 'crypto'
expect = require 'expect.js'
Multisource = require '../lib/multisource'

describe 'Multisource', ->
  it 'should recompose data piped to its sources', ->
    data = new Buffer [0, 1, 2, 3, 4, 5, 6, 7, 8]

    # Sequential
    multi = new Multisource
    multi.from(0).write data[0...3]
    multi.from(3).write data[3...6]
    multi.from(6).write data[6...9]
    (expect multi.read()).to.eql data

    # Not sequential
    multi = new Multisource
    multi.from(6).write data[6...9]
    multi.from(0).write data[0...3]
    multi.from(3).write data[3...6]
    (expect multi.read()).to.eql data

    # Overlap
    multi = new Multisource
    multi.from(0).write data[0...3]
    multi.from(6).write data[6...9]
    multi.from(2).write data[2...7]
    (expect multi.read()).to.eql data

    # Overlap 2
    multi = new Multisource
    multi.from(3).write data[3...6]
    multi.from(0).write data[0...9]
    (expect multi.read()).to.eql data

    # Catching up
    multi = new Multisource
    source1 = multi.from 0
    source2 = multi.from 0
    source1.write data[0...3]
    source2.write data[0...6]
    source1.write data[3...9]
    (expect multi.read()).to.eql data
