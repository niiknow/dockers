// outbounce_to_s3.js
var AWS = require('aws-sdk'), zlib = require("zlib"),
    util = require('util'), async = require("async"),
    Transform = require('stream').Transform;

AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_DEFAULT_REGION
});

exports.register = function () {
  this.logdebug("Initializing outbounce_to_s3");

  var config = this.config.get('aws_config.json')
  AWS.config.update(config.aws);

  this.bucket           = config.outbounce.bucket;
  this.fileExtension    = config.outbounce.fileExtension;
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
        var rst = {
          emailAddress: rcpt_to.address(),
          action: "failed",
          status: "UNKNOWN",
          codePrefix: "NA",
          hardBounce: false,
          diagnosticCode: rcpt_to.reason ? rcpt_to.reason : connection.bounce_error
        };

        // if you need a better handling/message, there's always AWS SES
        // this is a very naive diagnostic code parsing, but it work for
        // my use-case and logic of taking a hard stance on bounce
        try {
          if (typeof(rst.diagnosticCode) === 'string') {
            rst.codePrefix = rst.diagnosticCode.replace(/\D+/, '').trim().substr(0,1);
            rst.hardBounce = rst.codePrefix == '5';
          }
        } catch(e) {
          connection.loginfo('diagnostic code parsing error ', e + ' ', rst);
        }

        // since the status is stored on s3, we can always inspect
        // later/in-retrospective to remove the bounce record
        return rst;
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
  var isHard = innerMessage.bounce.bouncedRecipients[0].hardBounce;
  if (isHard) {
    innerMessage.notificationType = 'Bounce';
    innerMessage.bounce.bounceType = 'Permanent';
  }

  var body = JSON.stringify(innerMessage);
  var s3 = new AWS.S3();
  connection.logdebug(util.inspect(innerMessage, false, null));

  async.each(addresses, function (address, eachCallback) {
    var key = (address + plugin.fileExtension).toLowerCase();
    var params = {
      Bucket: plugin.bucket,
      Key: key,
      Body: body,
      ContentType: 'application/json',
      Tagging: isHard ? 'year=1' : 'month=3'
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
