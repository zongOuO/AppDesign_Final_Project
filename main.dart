import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String selectedValue = '臺北';
  String key = 'CWA-15D3F278-DD19-4A8A-8749-96E501C29814';
  late String apiUrl; // 使用 'late' 來延遲初始化
  // 定義 API 的 URL
  WeatherStation? weatherStation;
  WeatherElement? _weatherElement;

  void updateApiUrl() {
    apiUrl = 'https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-A0003-001?Authorization=$key&StationName=$selectedValue';
  }

  @override
  void initState() {
    super.initState();
    // 在初始化階段（Widget 第一次描繪時）觸發 API 請求
    _fetchApiData();
  }

  void _fetchApiData() {
    print('Fetching API data...');
    // 在這裡執行實際的 API 請求邏輯
    // 可能涉及到異步處理（例如使用 async/await）
    updateApiUrl();
    fetchData().then((data) {
      setState(() {
        weatherStation = data;
      });

      // 在這裡加入 SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('資料已更新'),
          duration: Duration(seconds: 1), // 設定 SnackBar 顯示的時間
        ),
      );
    }).catchError((error) {
      print(error);
    });
  }
  Widget _buildWeatherImage(String weather) {
    String imagePath = '';

    switch (weather.toLowerCase()) {
      case '晴':
        imagePath = 'assets/sun.png'; // 假設你的圖片在 assets 資料夾下
        break;
      case '陰':
        imagePath = 'assets/cloudy.png';
        break;
      case '陰有雨':
        imagePath = 'assets/rainy.png';
        break;
    // 其他天氣狀況的處理...
      default:
        imagePath = 'assets/default.png'; // 預設圖片
    }

    return Image.asset(
      imagePath,
      width: 200.0,
      height: 200.0,
    );
  }

  Future<WeatherStation> fetchData() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return WeatherStation.fromJson(data['records']['Station'][0]);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('天氣APP'),
        ),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: weatherStation != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('選擇城市：',style: TextStyle(fontSize: 24.0)),
            DropdownButton<String>(
              value: selectedValue,
              onChanged: (String? newValue) {
                setState(() {
                  selectedValue = newValue!;
                  updateApiUrl(); // 在這裡更新 API URL
                  _fetchApiData(); // 重新抓取數據
                });
              },
              items: <String>[
                '臺北', '新北', '基隆', '新竹' , '宜蘭' , '臺中',
                '高雄', '臺南', '嘉義', '澎湖' , '花蓮' , '臺東'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value,style: TextStyle(fontSize: 24.0),),
                );
              }).toList(),
            ),
            _buildWeatherImage(weatherStation!.weatherElement.weather),
            Text('城市： ${weatherStation!.geoInfo.countyName}', style: TextStyle(fontSize: 24.0)),
            Text('天氣情況： ${weatherStation!.weatherElement.weather}', style: TextStyle(fontSize: 24.0)),
            Text('目前溫度： ${weatherStation!.weatherElement.airTemperature}', style: TextStyle(fontSize: 24.0)),
            Text('最高溫度： ${weatherStation!.weatherElement.dailyExtreme.dailyHigh.airTemperature}', style: TextStyle(fontSize: 24.0)),
            Text('最低溫度： ${weatherStation!.weatherElement.dailyExtreme.dailyLow.airTemperature}', style: TextStyle(fontSize: 24.0)),
            Text('資料時間： ${weatherStation!.weatherElement.datetime}', style: TextStyle(fontSize: 20.0)),
          ],
        )
            : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 點擊按鈕時觸發更新資料的邏輯
          _fetchApiData();
        },
        tooltip: '更新資料',
        child: Icon(Icons.refresh),
      ),
    );
  }

}

class WeatherStation {
  String stationName;
  GeoInfo geoInfo;
  WeatherElement weatherElement;

  WeatherStation({
    required this.stationName,
    required this.geoInfo,
    required this.weatherElement,
  });

  factory WeatherStation.fromJson(Map<String, dynamic> json) {
    return WeatherStation(
      stationName: json['StationName'],
      geoInfo: GeoInfo.fromJson(json['GeoInfo']),
      weatherElement: WeatherElement.fromJson(json['WeatherElement']),
    );
  }
}

class GeoInfo {
  String countyName;

  GeoInfo({
    required this.countyName,
  });

  factory GeoInfo.fromJson(Map<String, dynamic> json) {
    return GeoInfo(
      countyName: json['CountyName'],
    );
  }
}

class WeatherElement {
  String weather;
  DailyExtreme dailyExtreme;
  double airTemperature;
  String datetime;

  WeatherElement({
    required this.weather,
    required this.dailyExtreme,
    required this.airTemperature,
    required this.datetime,
  });

  factory WeatherElement.fromJson(Map<String, dynamic> json) {
    return WeatherElement(
      weather: json['Weather'],
      dailyExtreme: DailyExtreme.fromJson(json['DailyExtreme']),
      airTemperature: (json['AirTemperature'] != null)
          ? json['AirTemperature'].toDouble()
          : 0.0,
      datetime: (json['Max10MinAverage'] != null &&
          json['Max10MinAverage']['Occurred_at'] != null &&
          json['Max10MinAverage']['Occurred_at']['DateTime'] != null)
          ? json['Max10MinAverage']['Occurred_at']['DateTime']
          : '',
    );
  }

}

class DailyExtreme {
  TemperatureInfo dailyLow;
  TemperatureInfo dailyHigh;

  DailyExtreme({
    required this.dailyLow,
    required this.dailyHigh,
  });

  factory DailyExtreme.fromJson(Map<String, dynamic> json) {
    return DailyExtreme(
      dailyLow: TemperatureInfo.fromJson(json['DailyLow']['TemperatureInfo'] ?? {}),
      dailyHigh: TemperatureInfo.fromJson(json['DailyHigh']['TemperatureInfo'] ?? {}),
    );
  }
}


class TemperatureInfo {
  double airTemperature;

  TemperatureInfo({
    required this.airTemperature,
  });

  factory TemperatureInfo.fromJson(Map<String, dynamic> json) {
    return TemperatureInfo(
      airTemperature: json['AirTemperature'] != null ? json['AirTemperature'].toDouble() : 0.0,
    );
  }
}

