# shelf_history_api_fallback

Shelf middleware to proxy requests through a specified index page, useful for Single Page Applications that utilise the HTML5 History API.

This is a Dart port of the Javascript [connect-history-api-fallback](https://github.com/bripkens/connect-history-api-fallback) middleware.

## Introduction

Single Page Applications (SPA) typically only utilise one index file that is
accessible by web browsers: usually `index.html`. Navigation in the application
is then commonly handled using client-side script with the help of the
[HTML5 History API](http://www.w3.org/html/wg/drafts/html/master/single-page.html#the-history-interface).
This results in issues when the user hits the refresh button or is directly
accessing a page other than the landing page, e.g. `/help` or `/help/online`
as the web server bypasses the index file to locate the file at this location.
As your application is a SPA, the web server will fail trying to retrieve the file and return a *404 - Not Found*
message to the user.

This tiny middleware addresses some of the issues. Specifically, it will change
the requested location to the index you specify (default being `index.html`)
whenever there is a request which fulfils the following criteria:

 1. The request is a GET request
 2. which accepts `text/html`,
 3. is not a direct file request, i.e. the requested path does not contain a
    `.` (DOT) character and
 4. does not match a pattern provided in options.rewrites (see options below)

## Usage

A simple usage example:

```dart
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_history_api_fallback/shelf_history_api_fallback.dart';

/// Start the server, it will serve at port 1234.
/// Then to test run this command:
/// curl --data "param1=value1" localhost:1234/a
main() {

  Handler handler = const Pipeline()
  .addMiddleware(logRequests())
  .addMiddleware(historyApiFallback())
  .addHandler((request) => new Response.ok("Got it!"));

  io.serve(handler, InternetAddress.ANY_IP_V4, 1234).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });

}
```

## Options
You can optionally pass options to the library when obtaining the middleware

```dart
var middleware = historyApiFallback(index: "index.html", rewrites: []);
```

### index
Override the index (default `index.html`)

```dart
historyApiFallback(index: 'default.html');
```

### rewrites
Override the index when the request url matches a regex pattern. You can either rewrite to a static string or use a function to transform the incoming request.

The following will rewrite a request that matches the `/\/soccer/` pattern to `/soccer.html`.
```dart
history(rewrites: [
    new Rewrite(from: /\/soccer/, to: (a, b) => '/soccer.html')
  ]
);
```

Alternatively functions can be used to have more control over the rewrite process.
For instance, the following listing shows how requests to `/libs/jquery/jquery.1.12.0.min.js` and the like
can be routed to `./bower_components/libs/jquery/jquery.1.12.0.min.js`. You can also make use of this if you
have an API version in the URL path.
```dart
history(rewrites: [
    new Rewrite(
      from: /^\/libs\/.*$/,
      to: (context) {
        return '/bower_components' + context.parsedUrl.pathname;
      )
    }
  ]
);
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/jonaskello/shelf_history_api_fallback/issues
