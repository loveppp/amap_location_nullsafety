import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amap_location_flutter_plugin/amap_location_flutter_plugin.dart';
import 'package:amap_location_flutter_plugin/amap_location_option.dart';
import 'package:permission_handler/permission_handler.dart';

/// Signature of callbacks that have no arguments and return no data.
typedef AddressCallback = void Function(String? address);

class LocationManager {
  late AddressCallback addressCallback;
  String? address;
  AmapLocationFlutterPlugin _locationPlugin = AmapLocationFlutterPlugin();
  static final LocationManager _instance = LocationManager._internal();

  //提供了一个工厂方法来获取该类的实例
  factory LocationManager() {
    return _instance;
  }

  // 通过私有方法_internal()隐藏了构造方法，防止被误创建
  LocationManager._internal() {
    // 初始化
    AmapLocationFlutterPlugin.setApiKey(
        "28bd43ed17d636692c8803e9e0d246b2", "dfb64c0463cb53927914364b5c09aba0");
    init();
  }

  // Singleton._internal(); // 不需要初始化

  void init() {
    if (Platform.isIOS) {
      requestAccuracyAuthorization();
    }
    _locationPlugin.onLocationChanged().listen((Map<String, Object> result) {
      print('1234');
      if (result['address'] != null) {
        address = result['address'] as String?;
      }else{
        address = null;
      }
      // print('获取到定位信息${result['address']}');
      addressCallback(address );
    });
    _setLocationOption();//必须放在监听的后面 fk a dog
  }

  ///设置定位参数
  void _setLocationOption() {
    if (null != _locationPlugin) {
      AMapLocationOption locationOption = new AMapLocationOption();

      ///是否单次定位
      locationOption.onceLocation = true;

      ///是否需要返回逆地理信息
      locationOption.needAddress = true;

      ///逆地理信息的语言类型
      locationOption.geoLanguage = GeoLanguage.DEFAULT;

      locationOption.desiredLocationAccuracyAuthorizationMode =
          AMapLocationAccuracyAuthorizationMode.ReduceAccuracy;

      locationOption.fullAccuracyPurposeKey = "AMapLocationScene";

      ///设置Android端连续定位的定位间隔
      locationOption.locationInterval = 2000;

      ///设置Android端的定位模式<br>
      ///可选值：<br>
      ///<li>[AMapLocationMode.Battery_Saving]</li>
      ///<li>[AMapLocationMode.Device_Sensors]</li>
      ///<li>[AMapLocationMode.Hight_Accuracy]</li>
      locationOption.locationMode = AMapLocationMode.Hight_Accuracy;

      ///设置iOS端的定位最小更新距离<br>
      locationOption.distanceFilter = -1;

      ///设置iOS端期望的定位精度
      /// 可选值：<br>
      /// <li>[DesiredAccuracy.Best] 最高精度</li>
      /// <li>[DesiredAccuracy.BestForNavigation] 适用于导航场景的高精度 </li>
      /// <li>[DesiredAccuracy.NearestTenMeters] 10米 </li>
      /// <li>[DesiredAccuracy.Kilometer] 1000米</li>
      /// <li>[DesiredAccuracy.ThreeKilometers] 3000米</li>
      locationOption.desiredAccuracy = DesiredAccuracy.Best;

      ///设置iOS端是否允许系统暂停定位
      locationOption.pausesLocationUpdatesAutomatically = false;

      ///将定位参数设置给定位插件
      _locationPlugin.setLocationOption(locationOption);
    }
  }

  ///停止定位
  void stopLocation() {
    _locationPlugin.stopLocation();
  }

  ///开始定位
  void startLocation(
      AddressCallback addressCallback) async {

    this.addressCallback = addressCallback;
    if (address != null ) {
      print('123');
      this.addressCallback(address);
      return;
    }
    requestPermission();
  }

  /// 动态申请定位权限
  void requestPermission() async {
    // 申请权限
    bool hasLocationPermission = await requestLocationPermission();
    if (hasLocationPermission) {
      print("定位权限申请通过");
      _locationPlugin.startLocation();
    } else {
      print("定位权限申请不通过");
      addressCallback(address);
    }
  }

  /// 申请定位权限
  /// 授予定位权限返回true， 否则返回false
  Future<bool> requestLocationPermission() async {
    //获取当前的权限
    var status = await Permission.location.status;
    if (status == PermissionStatus.granted) {
      //已经授权
      return true;
    } else {
      //未授权则发起一次申请
      status = await Permission.location.request();
      if (status == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  ///获取iOS native的accuracyAuthorization类型
  void requestAccuracyAuthorization() async {
    AMapAccuracyAuthorization currentAccuracyAuthorization =
        await _locationPlugin.getSystemAccuracyAuthorization();
    if (currentAccuracyAuthorization ==
        AMapAccuracyAuthorization.AMapAccuracyAuthorizationFullAccuracy) {
      print("精确定位类型");
    } else if (currentAccuracyAuthorization ==
        AMapAccuracyAuthorization.AMapAccuracyAuthorizationReducedAccuracy) {
      print("模糊定位类型");
    } else {
      print("未知定位类型");
    }
  }
}
