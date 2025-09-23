import 'package:get/get.dart';

import '../controllers/dashboard_manage_controller.dart';

class DashboardManageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardManageController>(
      () => DashboardManageController(),
    );
  }
}
