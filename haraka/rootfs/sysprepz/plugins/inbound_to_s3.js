// inbound_to_s3.js
// - store incoming valid host (host_list) mail to s3
//
const AWS = require("aws-sdk"), zlib = require("zlib"),
      util = require('util'), async = require("async"),
      Transform = require('stream').Transform;

exports.register = function () {
  this.logdebug("Initializing inbound_to_s3");

  var config = this.config.get('aws_config.json')
  AWS.config.update(config.aws);

  this.bucket           = config.inbound.bucket;
  this.fileExtension    = config.inbound.fileExtension;
  this.compress         = config.inbound.compress;
  this.copyAllAddresses = config.inbound.copyAllAddresses;
};

exports.hook_queue = function (next, connection) {
  var plugin = this;

  var transaction = connection.transaction;
  var emailTo = transaction.rcpt_to;

  var gzip = zlib.createGzip();
  var transformer = plugin.compress ? gzip : new TransformStream();
  var body = transaction.message_stream.pipe(transformer);

  var s3 = new AWS.S3();

  var addresses = plugin.copyAllAddresses ? transaction.rcpt_to : transaction.rcpt_to[0];

  async.each(addresses, function (address, eachCallback) {
    var key = address.host + '/' + address.user + "/" + transaction.uuid + plugin.fileExtension;

    var params = {
      Bucket: plugin.bucket,
      Key: key,
      Body: body
    };

    s3.upload(params).on('httpUploadProgress', function (evt) {
        plugin.logdebug("Uploading file... Status : " + util.inspect(evt));
    }).send(function (err, data) {
      plugin.logdebug("S3 Send response data : " + util.inspect(data));
      eachCallback(err);
    });
  }, function (err) {
    if (err) {
      plugin.logerror(err);
      next();
    } else {
      next(OK, "Email Accepted.");
    }
  });
};

exports.shutdown = function () {
  this.loginfo("Shutting down inbound_to_s3 plugin.");
};

//Dummy transform stream to help with a haraka issue. Can't use message_stream as a S3 API parameter without this.
var TransformStream = function() {
  Transform.call(this);
};
util.inherits(TransformStream, Transform);

TransformStream.prototype._transform = function(chunk, encoding, callback) {
  this.push(chunk);
  callback();
};
