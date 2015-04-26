// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library shelf_history_api_fallback.test;

import 'package:unittest/unittest.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_history_api_fallback/shelf_history_api_fallback.dart';

main() {
  group('Request tests', () {

//    Middleware middleware;
    Handler innerHandler = (Request req) => new Response.ok("Got it!");

//    setUp(() {
//      middleware = historyApiFallback();
//    });

    test('First Test', () {
      var middleware = historyApiFallback();
      var handler = middleware(innerHandler);
      var resp = handler(new Request("POST", Uri.parse("http://localhost/index.html")));
      expect(resp, isNotNull);
    });

    test('Rewrite Test', () {
      var middleware = historyApiFallback(rewrites: [
        new Rewrite("^\/libs\/.*\$",
            (parsedUrl, match) => parsedUrl.replace(path: '/bower_components' + parsedUrl.path))
      ]);
      var handler = middleware(innerHandler);
      var resp = handler(new Request("GET", Uri.parse("http://localhost/index.html")));
      expect(resp, isNotNull);
    });

  });

}
