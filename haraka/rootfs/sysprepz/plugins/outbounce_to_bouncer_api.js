// outbounce_to_bouncer_api.js
// - store bounce to bouncer api: https://github.com/niiknow/email-bouncer-api
//
const http  = require('https'),
      util = require('util');

exports.register = function () {
  this.logdebug("Initializing outbounce_to_bouncer_api");

  this.host = this.config.get('outbounce_to_bouncer_api.host').trim();
};

exports.hook_bounce = function (next, connection) {
  connection.logdebug(util.inspect(connection, false, null));

  var plugin    = this;
  var date      = new Date();
  var addresses = connection.todo.rcpt_to.map(function (rcpt_to) {
    return rcpt_to.address()
  })

  var innerMessage = {
    notificationType: "Bounce",
    bounce: {
      bounceType: "Transient",
      bounceSubType: "General",
      bouncedRecipients: connection.todo.rcpt_to.map(function (rcpt_to) {
        var rst = {
          emailAddress: rcpt_to.address(),
          action: "failed",
          status: "UNKNOWN",
          codePrefix: "UNKNOWN",
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
    innerMessage.bounce.bounceType = 'Permanent';
  }

  var body = JSON.stringify({ Message: JSON.stringify(innerMessage), Type: 'Notification' });
  connection.logdebug(util.inspect(innerMessage, false, null));

  // single post that include all email addresses
  const options = {
    hostname: plugin.host,
    port: 443,
    path: '/api/v1/bounces/aws-ses',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': body.length
    }
  }

  plugin.loginfo('outbounce_to_bouncer_api sending to: ' + plugin.host);

  const req = http.request(options, (res) => {
    plugin.loginfo('outbounce_to_bouncer_api sent');
  });

  req.on('error', (err) => {
    plugin.logerror('outbounce_to_bouncer_api error: ' + err);
  });

  req.write(body);
  req.end();

  next(OK);
};
