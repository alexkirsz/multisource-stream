(function() {
  var Multisource, crypto, should, _;

  crypto = require('crypto');

  should = require('should');

  _ = require('lodash');

  Multisource = require('../lib/multisource');

  describe('Writing parts of data to the sources of a Multisource', function() {
    return it('should return the input data recomposed (random)', function() {
      var bytesToWrite, chunk, data, dataLength, end, multi, offset, part, parts, source, sourceId, sources, start, _i, _len;
      dataLength = 1000000;
      multi = new Multisource({
        highWaterMark: dataLength
      });
      data = crypto.randomBytes(dataLength);
      parts = [];
      offset = 0;
      while (offset < dataLength) {
        start = offset - (Math.floor(Math.random() * dataLength / 100));
        if (start < 0) {
          start = 0;
        }
        end = offset + (Math.floor(Math.random() * dataLength / 10000));
        if (end > dataLength) {
          end = dataLength;
        }
        parts.push([start, end]);
        if (end > offset) {
          offset = end;
        }
      }
      parts = _.shuffle(parts);
      sources = [];
      for (_i = 0, _len = parts.length; _i < _len; _i++) {
        part = parts[_i];
        source = {
          offset: 0,
          length: part[1] - part[0],
          data: data.slice(part[0], part[1]),
          stream: multi.from(part[0], {
            highWaterMark: dataLength
          })
        };
        sources.push(source);
      }
      while (multi.offset < dataLength) {
        sourceId = Math.floor(Math.random() * sources.length);
        source = sources[sourceId];
        bytesToWrite = Math.ceil(Math.random() * source.length);
        if (bytesToWrite > source.length - source.offset) {
          bytesToWrite = source.length - source.offset;
        }
        chunk = source.data.slice(source.offset, source.offset + bytesToWrite);
        source.offset += bytesToWrite;
        if (source.offset === source.length) {
          sources.splice(sourceId, 1);
        }
        source.stream.write(chunk);
      }
      return multi.read().toString().should.equal(data.toString());
    });
  });

}).call(this);
