import 'package:flutter/material.dart';
import 'dart:async';

import 'package:test_ffi/test_ffi.dart' as test_ffi;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int sumResult;
  late Future<int> sumAsyncResult;

  late String platformResult;
  late int minResult;
  late int maxResult;

  @override
  void initState() {
    super.initState();
    sumResult = test_ffi.sum(1, 2);
    sumAsyncResult = test_ffi.sumAsync(3, 4);

    platformResult = test_ffi.platform();
    minResult = test_ffi.min(99, 101);
    maxResult = test_ffi.max(99, 101);
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'sum = $sumResult',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                FutureBuilder<int>(
                  future: sumAsyncResult,
                  builder: (BuildContext context, AsyncSnapshot<int> value) {
                    final displayValue =
                        (value.hasData) ? value.data : 'loading';
                    return Text(
                      'await sumAsync(3, 4) = $displayValue',
                      style: textStyle,
                      textAlign: TextAlign.center,
                    );
                  },
                ),

                // 平台
                spacerSmall,
                Text(
                  'platform = $platformResult',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),

                // 调用动态库结果
                // IOS不支持动态库，所以在IOS设备上运行返回-1
                spacerSmall,
                Text(
                  'min = $minResult',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),

                // 调用静态库结果
                spacerSmall,
                Text(
                  'max = $maxResult',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
