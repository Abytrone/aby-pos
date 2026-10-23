import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/aby_mark.dart';
import '../controllers/start_controller.dart';

class StartView extends GetView<StartController> {
  const StartView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: AbyMark(size: 64)));
  }
}
