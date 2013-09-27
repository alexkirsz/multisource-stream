(function() {
  var Duplex, Source,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Duplex = require('stream').Duplex;

  module.exports = Source = (function(_super) {
    __extends(Source, _super);

    function Source(options) {
      Source.__super__.constructor.call(this, options);
      this._writing = true;
    }

    Source.prototype._read = function(size) {
      if (!this._writing) {
        this._writing = true;
        return this._writingCallback();
      }
    };

    Source.prototype._write = function(chunk, encoding, callback) {
      this._writing = this.push(chunk);
      if (!this._writing) {
        return this._writingCallback = callback;
      } else {
        return callback();
      }
    };

    return Source;

  })(Duplex);

}).call(this);
