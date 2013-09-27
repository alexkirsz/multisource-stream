(function() {
  var Multisource, Readable, Source, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Readable = require('stream').Readable;

  _ = require('lodash');

  Source = require('./source');

  module.exports = Multisource = (function(_super) {
    __extends(Multisource, _super);

    function Multisource(options) {
      this.from = __bind(this.from, this);
      this._readAheads = __bind(this._readAheads, this);
      this._readSource = __bind(this._readSource, this);
      this._read = __bind(this._read, this);
      Multisource.__super__.constructor.call(this, options);
      this.offset = 0;
      this._sources = [];
      this._readables = [];
      this._aheads = [];
      this._reading = true;
    }

    Multisource.prototype._read = function(size) {
      var prevOffset, source;
      this._reading = true;
      prevOffset = this.offset;
      while (this._reading && this._readables.length > 0) {
        source = this._readables.shift();
        this._readSource(source);
      }
      if (this.offset !== prevOffset) {
        return this._readAheads();
      }
    };

    Multisource.prototype._readSource = function(source) {
      var buffer, delta, slice;
      buffer = source.stream.read();
      if (buffer === null) {
        return false;
      }
      delta = this.offset - source.offset;
      if (delta > buffer.length) {
        source.offset += buffer.length;
        return false;
      } else {
        if (delta === 0) {
          this._reading = this.push(buffer);
        } else {
          slice = buffer.slice(delta);
          this._reading = this.push(slice);
        }
        source.offset += buffer.length;
        this.offset = source.offset;
        return true;
      }
    };

    Multisource.prototype._maybeReadSource = function(source) {
      if (this._reading) {
        return this._readSource(source);
      } else {
        this._readables.push(source);
        return false;
      }
    };

    Multisource.prototype._readAheads = function() {
      var source, _results;
      _results = [];
      while (this._aheads.length > 0 && this._aheads[0].offset <= this.offset) {
        source = this._aheads.shift();
        _results.push(this._maybeReadSource(source));
      }
      return _results;
    };

    Multisource.prototype.from = function(offset, options) {
      var i, source,
        _this = this;
      source = {
        stream: new Source(options),
        offset: offset
      };
      source.id = (this._sources.push(source)) - 1;
      if (source.offset > this.offset) {
        i = _.sortedIndex(this._aheads, source, 'offset');
        this._aheads.splice(i, 0, source);
      }
      source.stream.on('readable', function() {
        var oldOffset, readable;
        if (source.offset <= _this.offset) {
          oldOffset = source.offset;
          readable = _this._maybeReadSource(source);
          if (readable) {
            return _this._readAheads();
          }
        }
      });
      source.stream.on('end', function() {
        return _this._sources.splice(source.id, 1);
      });
      return source.stream;
    };

    return Multisource;

  })(Readable);

}).call(this);
