const http = require('https');

exports.register = function () {
  this.cdnUrl = this.config.get('outbounce_guard.cdn');
}

exports.hook_rcpt_ok = function (next, connection, rcpt) {
  const plugin = this;

  // no cdn defined, go to next
  if (!plugin.cdnUrl) {
    return next();
  }

  const rcpt_to = rcpt.address();
  const url = plugin.cdnUrl.trim() + encodeURIComponent(rcpt_to.toLowerCase().trim());
  plugin.logdebug(plugin, url);

  var str = '';

  const req = http.request(url, (res) => {
    // plugin.logdebug(plugin, res);
    res.on('data', function (chunk) {
      str += chunk;
    });

    res.on('end', function () {
      if (str.indexOf('true') > -1) {
        return next();
      }

      return next(DENYSOFT, 'Error: user has bounce history - ' + rcpt_to);
    });
  });

  req.on('error', (err) => {
    // on error, proceed to next
    return next();
  });

  req.end();
}
