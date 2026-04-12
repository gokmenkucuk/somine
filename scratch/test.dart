import 'dart:io';
import 'package:html/parser.dart' show parse;

void main() async {
  String url = 'https://pin.it/5rVX9WJis';
  
  // Resolve redirect
  final client = HttpClient();
  client.userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15';
  
  final request = await client.getUrl(Uri.parse(url));
  request.followRedirects = true;
  request.maxRedirects = 10;
  
  final response = await request.close();
  final finalUri = response.redirects.isNotEmpty ? response.redirects.last.location : request.uri;
  print("Final URI: $finalUri");
  
  // Now fetch final URL with proper headers
  final req2 = await client.getUrl(finalUri);
  req2.headers.set('User-Agent', client.userAgent!);
  final res2 = await req2.close();
  
  final contents = await res2.transform(SystemEncoding().decoder).join();
  
  final document = parse(contents);
  var tags = document.querySelectorAll('meta');
  for (var tag in tags) {
    if (tag.attributes['property']?.contains('title') == true || tag.attributes['name']?.contains('title') == true || tag.attributes['property']?.contains('description') == true || tag.attributes['name']?.contains('description') == true) {
      print("${tag.attributes['property'] ?? tag.attributes['name']}: ${tag.attributes['content']}");
    }
  }
}
