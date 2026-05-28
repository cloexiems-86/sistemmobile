import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  for (int i = 1; i <= 20; i++) {
    var url = Uri.parse('https://farel.dwirez.app/catin_api/get_sertifikat.php?user_id=' + i.toString());
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print('user_id: $i -> is_lulus: ${data['is_lulus']}, url: ${data['url_sertifikat']}');
    }
  }
}
