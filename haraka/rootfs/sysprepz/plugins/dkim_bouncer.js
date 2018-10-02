// dkim_bouncer.js
// - check if dkim match dns, otherwise, disable dkim signing
//
const fs         = require('fs');
const path       = require('path');
const dns        = require('dns');
const async      = require("async")
const addrparser = require('address-rfc2822');

exports.register = function () {
  this.logdebug('Initializing dkim_bouncer');
  this.myDomain   = this.load_key('me');
  this.publicKey  = this.load_key('dkim/'+this.myDomain+'/public');
  this.mySelector = this.load_key('dkim/'+this.myDomain+'/selector');
  this.baseDir    = process.env.HARAKA || '';
}

exports.load_key = function (file) {
  return this.parseKeyOnly(this.config.get(file, 'data').join('\n'));
};

exports.hook_queue_outbound = function (next, connection) {
  const plugin = this;
  let selector = plugin.mySelector;
  let domain = plugin.get_sender_domain(connection);
  let publicKey = this.publicKey;

  if (!domain) {
    connection.transaction.results.add(plugin, {skip: "sending domain not detected " + domain, emit: true });
    return next();
  }

  plugin.get_key_dir(domain, function(keydir) {
    if (keydir) {
      plugin.logdebug(plugin, 'dkim_domain: '+domain);
      publicKey = plugin.load_key('dkim/'+domain+'/public');
      selector  = plugin.load_key('dkim/'+domain+'/selector');
    } else {
      // auto create dkim symbolic link
      const baseDir = process.env.HARAKA || '';
      fs.symlinkSync(plugin.myDomain+'/', path.resolve(baseDir + '/config/dkim/'+domain), 'dir');
    }

    if (!selector) {
      connection.transaction.results.add(plugin, {skip: "sending domain selector not detected " + selector, emit: true });
      return next();
    }

    if (!publicKey) {
      connection.transaction.results.add(plugin, {skip: "sending domain public key not found", emit: true });
      return next();
    }

    var host = [selector, '_domainkey', domain].join('.');
    dns.resolveTxt(host, function(err, result) {
      if (err) {
        return next(OK, 'Error: ' + err);
      }

      if (!result || !result.length) {
        return next(OK, 'Error: Selector not found - ' + host);
      }

      var data = {};
      [].concat(result[0] || []).join('').split(/;/).forEach(function(row) {
          var key, val;
          row = row.split('=');
          key = (row.shift() || '').toString().trim();
          val = (row.join('=') || '').toString().trim();
          data[key] = val;
      });
      plugin.logdebug(plugin, JSON.stringify(data));

      if (!data.p) {
        return next(OK, 'Error: DNS TXT record does not seem to be a DKIM value - ' + host);
      }

      // if foundKey does not match local key, reject
      var foundKey = plugin.parseKeyOnly(data.p);
      if (foundKey != publicKey) {
        plugin.logdebug('Host: '+ domain, ' Local key: '+publicKey, ' DNS key: '+foundKey);
        next(OK, 'Error: Local DKIM (public key) does not match DNS record - ' + host);
        return;
      }

      return next();
    });
  });
}

exports.parseKeyOnly = function (data) {
  var rst = data.trim().split('\n');
  if (rst.length > 2) {
    rst = rst.slice(1, -1);
  }

  data = rst.join(' ').replace(/\s+/gim, '').replace(/\"+/gim, '').trim();
  return data;
}

exports.get_key_dir = function (domain, cb) {
  var plugin = this;

  if (!domain) { return cb(); }

  // split the domain name into labels
  var labels     = domain.split('.');
  var haraka_dir = process.env.HARAKA || './';

  // list possible matches (ex: mail.example.com, example.com, com)
  var dom_hier = [];
  for (var i=0; i<labels.length; i++) {
    var dom = labels.slice(i).join('.');
    dom_hier[i] = haraka_dir + "/config/dkim/"+dom;
  }
  plugin.logdebug(plugin, dom_hier);

  async.filter(dom_hier, function(filePath, callback) {
    fs.access(filePath, function(err) {
        callback(null, !err)
    });
  }, function(err, results) {
    // results now equals an array of the existing files
    cb(results[0]);
  });
};

exports.get_sender_domain = function (connection) {
  const plugin = this;
  if (!connection.transaction) {
    plugin.logerror(plugin, 'no transaction!')
    return;
  }

  const txn = connection.transaction;

  // fallback to Envelope FROM when header parsing fails
  let domain;
  if (txn.mail_from.host) {
    try { domain = txn.mail_from.host.toLowerCase(); }
    catch (e) {
      plugin.logerror(plugin, e);
    }
  }

  if (!txn.header) return domain;

  // the DKIM signing key should be aligned with the domain in the From
  // header (see DMARC). Try to parse the domain from there.
  const from_hdr = txn.header.get('From');
  if (!from_hdr) return domain;

  // The From header can contain multiple addresses and should be
  // parsed as described in RFC 2822 3.6.2.
  let addrs;
  try {
    addrs = addrparser.parse(from_hdr);
  }
  catch (e) {
    plugin.logerror(`address-rfc2822 failed to parse From header: ${from_hdr}`)
    return domain;
  }
  if (!addrs || ! addrs.length) return domain;

  // If From has a single address, we're done
  if (addrs.length === 1 && addrs[0].host) {
    let fromHost = addrs[0].host();
    if (fromHost) {
      // don't attempt to lower a null or undefined value #1575
      fromHost = fromHost.toLowerCase();
    }
    return fromHost;
  }

  // If From has multiple-addresses, we must parse and
  // use the domain in the Sender header.
  const sender = txn.header.get('Sender');
  if (sender) {
    try {
      domain = (addrparser.parse(sender))[0].host().toLowerCase();
    }
    catch (e) {
      plugin.logerror(e);
    }
  }
  return domain;
}
