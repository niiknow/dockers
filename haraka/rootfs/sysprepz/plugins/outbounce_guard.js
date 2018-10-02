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
  const url = plugin.cdnUrl.trim() + rcpt_to.toLowerCase().trim() + '.json';
  plugin.logdebug(plugin, url);

  const req = http.request(url, (res) => {
    // plugin.logdebug(plugin, res);
    if (res.statusCode < 200 || res.statusCode > 299) {
      return next();
    }

    return next(DENYSOFT, 'Error: user has bounce history - ' + rcpt_to);
  });

  req.on('error', (err) => {
    // on error, proceed to next
    return next();
  });

  req.end();
}
