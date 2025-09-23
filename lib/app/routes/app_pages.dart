import 'package:get/get.dart';

import '../modules/dashboard_manage/bindings/dashboard_manage_binding.dart';
import '../modules/dashboard_manage/views/dashboard_manage_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD_MANAGE,
      page: () =>  DashboardManageView(),
      binding: DashboardManageBinding(),
    ),
  ];
}
