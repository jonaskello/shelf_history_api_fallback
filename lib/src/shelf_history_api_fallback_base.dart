// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library shelf_history_api_fallback.base;

import 'dart:async';
import 'package:shelf/shelf.dart';

typedef Uri RewriteRule(Uri parsedUrl, Match match);

Middleware historyApiFallback({String index: "/index.html", List<Rewrite> rewrites: const []}) {
  return new HistoryApiFallbackMiddleware(index: index, rewrites: rewrites).middleware;
}

class Rewrite {
  final String from;
  final RewriteRule to;
  Rewrite(this.from, this.to);
}

class HistoryApiFallbackMiddleware {

  final String index;
  final List<Rewrite> rewrites;

  HistoryApiFallbackMiddleware({this.index: "/index.html", this.rewrites: const []});

  Middleware get middleware => _createHandler;

  Handler _createHandler(Handler innerHandler) {
    return (Request request) => _handle(request, innerHandler);
  }

  Future<Response> _handle(Request req, Handler innerHandler) async {

    var headers = req.headers;
    if (req.method != 'GET') {
      logger("Not rewriting ${req.method} ${req.url} because the method is not GET.");
      return innerHandler(req);
    }
    else if (req.headers == null || req.headers["accept"].length == 0) {
      logger("Not rewriting ${req.method} ${req.url} because the client did not send an HTTP accept header.");
      return innerHandler(req);
    } else if (headers["accept"].indexOf('application/json') == 0) {
      logger("Not rewriting ${req.method} ${req.url} because the client prefers JSON.");
      return innerHandler(req);
    }
    else if (!acceptsHtml(headers["accept"])) {
      logger("Not rewriting ${req.method} ${req.url} because the client does not accept HTML.");
      return innerHandler(req);
    }

    var parsedUrl = req.requestedUri;
    String rewriteTarget;
    for (var i = 0; i < rewrites.length; i++) {
      var rewrite = rewrites[i];
      var match = parsedUrl.path.matchAsPrefix(rewrite.from);
      if (match != null) {
        Uri rewriteTargetUri = evaluateRewriteRule(parsedUrl, match, rewrite.to);
        logger("Rewriting, ${req.method} ${req.url} to $rewriteTarget");
        var newRequest = new Request("GET", rewriteTargetUri);
        return innerHandler(newRequest);
      }
    }

    if (parsedUrl.path.indexOf('.') != -1) {
      logger("Not rewriting ${req.method} ${req.url} because the path includes a dot (.) character.");
      return innerHandler(req);
    }

    rewriteTarget = index;
    logger("Rewriting, ${req.method} ${req.url} to $rewriteTarget");
    var rewriteTargetUri = req.requestedUri.replace(path: rewriteTarget);
    var newRequest = new Request("GET", rewriteTargetUri);
    return innerHandler(newRequest);

  }

  Uri evaluateRewriteRule(Uri parsedUrl, Match match, RewriteRule rule) {
    return rule(parsedUrl, match);
  }

  bool acceptsHtml(header) {
    return header.indexOf('text/html') != -1 || header.indexOf('*/*') != -1;
  }

  void logger(String msg) {
    print(msg);
  }

}
