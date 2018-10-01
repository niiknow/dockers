// outbound_bounce_to_s3.js
var AWS = require('aws-sdk'), util = require('util');

AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION
});

exports.register = function () {
  this.logdebug("Initializing outbound_bounce_to_s3");

  this.s3Bucket         = process.env.AWS_BUCKET;
  this.zipBeforeUpload  = true;
  this.fileExtension    = '.json';
  this.copyAllAddresses = true;
  this.bucketPrefix     = 'email/outbound/';
};

exports.hook_bounce = function (next, connection) {
  connection.logdebug(util.inspect(connection, false, null));

  var plugin    = this;
  var date      = new Date();
  var addresses = connection.todo.rcpt_to.map(function (rcpt_to) {
    return rcpt_to.address()
  })

  var innerMessage = {
    notificationType: "Complaint",
    bounce: {
      bounceType: "Transient",
      bounceSubType: "General",
      bouncedRecipients: connection.todo.rcpt_to.map(function (rcpt_to) {
        return {
          emailAddress: rcpt_to.address(),
          action: "failed",
          status: "UNKNOWN",
          diagnosticCode: rcpt_to.reason ? rcpt_to.reason : connection.bounce_error
        };
      }),
      timestamp: date.toISOString(),
      feedbackId: "UNKNOWN",
      reportingMTA: "UNKNOWN"
    },
    mail: {
      timestamp: date.toISOString(),
      source: connection.todo.mail_from.original,
      sourceArn: "N/A",
      sourceIp: "UNKNOWN",
      sendingAccountId: "UNKNOWN",
      messageId: connection.todo.uuid,
      destination: addresses
    }
  };

  connection.logdebug(util.inspect(innerMessage, false, null));
  var addresses = plugin.copyAllAddresses ? transaction.rcpt_to : transaction.rcpt_to[0];

  async.each(, function (address, eachCallback) {
    var key = address.user + plugin.fileExtension;

    var params = {
      Bucket: plugin.s3Bucket,
      Key: plugin.bucketPrefix + key,
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
      next(OK);
    }
  });
};
