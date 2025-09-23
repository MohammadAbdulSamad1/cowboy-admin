import 'package:dedicated_cow_boy_admin/app/modules/admin_manage.dart/view.dart';
import 'package:dedicated_cow_boy_admin/app/modules/auth/auth.dart';
import 'package:dedicated_cow_boy_admin/app/modules/auth/controller.dart';
import 'package:dedicated_cow_boy_admin/app/modules/db.dart';
import 'package:dedicated_cow_boy_admin/app/modules/listings.dart';
import 'package:dedicated_cow_boy_admin/app/modules/subscriptions/subscriptions.dart';
import 'package:dedicated_cow_boy_admin/app/modules/useraccounts.dart';
import 'package:dedicated_cow_boy_admin/app/modules/users.dart';
import 'package:dedicated_cow_boy_admin/app/new/auth_service.dart';
import 'package:dedicated_cow_boy_admin/app/services/admin_service.dart';
import 'package:dedicated_cow_boy_admin/firebase_options.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecurityService.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize AuthService first as it's a dependency for SignInController
  await Get.putAsync(() => AuthService().init());
  await Get.putAsync(() => AdminService().onInit());
  Get.put(AuthController(), permanent: true);
  Get.put(NavigationController(), permanent: true);

  runApp(const ProviderScope(child: AdminPanelApp()));
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'popins', // 👈 Set default font
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/auth',
      getPages: AppRoutes.routes,
    );
  }
}

// Responsive Breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
}

// Simplified Security Service
class SecurityService {
  static late encrypt.Encrypter _encrypter;
  static late encrypt.IV _iv;
  static const String _encryptionKey = 'Your32BytesLongEncryptionKey!';

  static Future<void> initialize() async {
    final key = encrypt.Key.fromUtf8(_encryptionKey);
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
    _iv = encrypt.IV.fromLength(16);
  }

  static String encryptData(String data) {
    final encrypted = _encrypter.encrypt(data, iv: _iv);
    return encrypted.base64;
  }

  static String decryptData(String encryptedData) {
    final decrypted = _encrypter.decrypt64(encryptedData, iv: _iv);
    return decrypted;
  }

  static Future<void> secureStorageWrite(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, encryptData(value));
  }

  static Future<String?> secureStorageRead(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedValue = prefs.getString(key);
    return encryptedValue != null ? decryptData(encryptedValue) : null;
  }
}

// Enhanced Navigation Controller with drawer state
class NavigationController extends GetxController {
  var currentIndex = 0.obs;
  var currentRoute = '/dashboard'.obs;
  var isDrawerOpen = false.obs;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    DashboardScreen(),
    const ManageListingsScreen(),
    const ResponsiveAdminReportsScreen(),
    const UserAccountsScreen(),
    const AdminManagementScreen(),
    SubscriptionManagementScreen(),
  ];

  Widget get currentPage => _pages[currentIndex.value];

  void navigateToIndex(int index, String route) {
    if (currentIndex.value != index) {
      currentIndex.value = index;
      currentRoute.value = route;
      Get.parameters['route'] = route;

      // Close drawer on mobile after navigation
      if (scaffoldKey.currentState?.isDrawerOpen == true) {
        scaffoldKey.currentState?.closeDrawer();
      }
    }
  }

  void navigateToRoute(String route) {
    final index = MenuItems.getIndexForRoute(route);
    if (index != -1) {
      navigateToIndex(index, route);
    }
  }

  void toggleDrawer() {
    if (scaffoldKey.currentState?.isDrawerOpen == true) {
      scaffoldKey.currentState?.closeDrawer();
    } else {
      scaffoldKey.currentState?.openDrawer();
    }
  }

  void closeDrawer() {
    if (scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(Get.context!).pop();
    }
  }
}

// Authentication State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Simplified routes
class AppRoutes {
  static final List<GetPage> routes = [
    GetPage(name: '/auth', page: () => AuthScreen()),
    GetPage(
      name: '/dashboard',
      page: () => const MainAdminScreen(),
      // middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/dashboard/:route',
      page: () => const MainAdminScreen(),
      // middlewares: [AuthMiddleware()],
    ),
  ];
}

// Simplified Auth Middleware
// class AuthMiddleware extends GetMiddleware {
//   @override
//   RouteSettings? redirect(String? route) {
//     final authService = Get.find<AuthService>();
//     final user = authService.currentUser;
//     if (user == null && route != '/auth') {
//       return const RouteSettings(name: '/auth');
//     }
//     if (user != null && route == '/auth') {
//       return const RouteSettings(name: '/dashboard');
//     }
//     return null;
//   }
// }

// Main Admin Screen
class MainAdminScreen extends StatelessWidget {
  const MainAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    // Check current user immediately
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/auth');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If user exists, show dashboard immediately
    return const ResponsiveAdminDashboard();
  }
}

// Responsive Admin Dashboard
class ResponsiveAdminDashboard extends StatelessWidget {
  const ResponsiveAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find();
    final bool isMobile = ResponsiveBreakpoints.isMobile(context);

    return Scaffold(
      key: navController.scaffoldKey,
      appBar: isMobile ? _buildMobileAppBar(navController) : null,
      drawer: isMobile ? const ResponsiveDrawer() : null,
      body: Row(
        children: [
          // Show sidebar only on tablet and desktop
          if (!isMobile) const ResponsiveSidebar(),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isMobile ? 4.0 : 4.0),
              child: Obx(() => navController.currentPage),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(NavigationController navController) {
    return AppBar(
      backgroundColor: const Color(0xFF364C63),
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => navController.toggleDrawer(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => _showLogoutConfirmation(),
        ),
      ],
    );
  }

  void _showLogoutConfirmation() {
    final AdminController controller = Get.find<AdminController>();
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Responsive Sidebar for Desktop/Tablet
class ResponsiveSidebar extends ConsumerWidget {
  const ResponsiveSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AdminController controller = Get.put(AdminController());
    final NavigationController navController = Get.find<NavigationController>();
    final authState = ref.watch(authStateProvider);
    final bool isTablet = ResponsiveBreakpoints.isTablet(context);

    return authState.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return Obx(
          () => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width:
                controller.sidebarCollapsed.value ? 80 : (isTablet ? 280 : 355),
            color: const Color(0xFF364C63),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Logo
                _buildLogo(controller.sidebarCollapsed.value),
                const SizedBox(height: 40),

                // Toggle button (only show on desktop)
                if (!isTablet) _buildToggleButton(controller),
                const SizedBox(height: 20),

                // Menu Items
                Expanded(
                  child: ListView.builder(
                    itemCount: MenuItems.items.length,
                    itemBuilder: (context, index) {
                      final item = MenuItems.items[index];
                      return Obx(() {
                        final isActive =
                            navController.currentIndex.value == index;
                        return SidebarMenuItem(
                          item: item,
                          isActive: isActive,
                          onTap:
                              () => navController.navigateToIndex(
                                index,
                                item.route,
                              ),
                          isCollapsed:
                              controller.sidebarCollapsed.value && !isTablet,
                        );
                      });
                    },
                  ),
                ),

                // Logout button
                _buildLogoutButton(controller),
              ],
            ),
          ),
        );
      },
      loading:
          () => Container(
            width: 80,
            color: const Color(0xFF364C63),
            child: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, _) => Container(
            width: 80,
            color: const Color(0xFF364C63),
            child: Center(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
    );
  }

  Widget _buildLogo(bool isCollapsed) {
    return Container(
      height: 108,
      width: double.infinity,
      color: Color(0xff364C63),
      child: Center(
        child:
            isCollapsed
                ? const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 40,
                )
                : Image.asset('assets/images/web_logo.png', height: 100),
      ),
    );
  }

  Widget _buildToggleButton(AdminController controller) {
    return GestureDetector(
      onTap: controller.toggleSidebar,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        child: Icon(
          controller.sidebarCollapsed.value ? Icons.menu_open : Icons.menu,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AdminController controller) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.white),
        title:
            !controller.sidebarCollapsed.value
                ? const Text('Logout', style: TextStyle(color: Colors.white))
                : null,
        onTap: () => _showLogoutConfirmation(controller),
      ),
    );
  }

  void _showLogoutConfirmation(AdminController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Mobile Drawer
class ResponsiveDrawer extends StatelessWidget {
  const ResponsiveDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();
    final authService = Get.find<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) return const SizedBox.shrink();

    return Drawer(
      backgroundColor: const Color(0xFF364C63),
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 200,
            width: double.infinity,
            color: Color(0xff364C63),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 60),
                SizedBox(height: 16),
                Text(
                  'ADMIN PANEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: MenuItems.items.length,
              itemBuilder: (context, index) {
                final item = MenuItems.items[index];
                return Obx(() {
                  final isActive = navController.currentIndex.value == index;
                  return DrawerMenuItem(
                    item: item,
                    isActive: isActive,
                    onTap: () {
                      navController.navigateToIndex(index, item.route);
                      navController.closeDrawer();
                    },
                  );
                });
              },
            ),
          ),

          // User Info and Logout
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            onTap: () {
              navController.closeDrawer();
              _showLogoutConfirmation();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    final AdminController controller = Get.find<AdminController>();
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Enhanced Admin Controller
class AdminController extends GetxController {
  var isLoading = false.obs;
  var sidebarCollapsed = false.obs;

  void toggleSidebar() => sidebarCollapsed.toggle();
  void setLoading(bool loading) => isLoading.value = loading;

  Future<void> logout() async {
    try {
      setLoading(true);

      await FirebaseAuth.instance.signOut();
      Get.offAllNamed('/auth');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Logout failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      setLoading(false);
    }
  }
}

// Sidebar Menu Item for Desktop/Tablet
class SidebarMenuItem extends StatelessWidget {
  final MenuItem item;
  final bool isActive;
  final VoidCallback onTap;
  final bool isCollapsed;

  const SidebarMenuItem({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF2B342) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: isActive ? Colors.black87 : Colors.white,
              size: 20,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: isActive ? Colors.black87 : Colors.white,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Drawer Menu Item for Mobile
class DrawerMenuItem extends StatelessWidget {
  final MenuItem item;
  final bool isActive;
  final VoidCallback onTap;

  const DrawerMenuItem({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF2B342) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isActive ? Colors.black87 : Colors.white,
          size: 24,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isActive ? Colors.black87 : Colors.white,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// Menu Item Model
class MenuItem {
  final String title;
  final String route;
  final IconData icon;

  const MenuItem({
    required this.title,
    required this.route,
    required this.icon,
  });
}

// Menu Items Configuration
class MenuItems {
  static const List<MenuItem> items = [
    MenuItem(title: 'Dashboard', route: '/dashboard', icon: Icons.dashboard),
    MenuItem(
      title: 'Manage Listings',
      route: '/managelistings',
      icon: Icons.home,
    ),
    MenuItem(title: 'Users Reports', route: '/users', icon: Icons.people),
    MenuItem(
      title: 'Users Accounts',
      route: '/products',
      icon: Icons.inventory,
    ),
    MenuItem(
      title: 'Admins',
      route: '/adminsmanage',
      icon: Icons.admin_panel_settings,
    ),
    MenuItem(
      title: 'Subscriptions',
      route: '/subscriptions',
      icon: Icons.subscriptions,
    ),
  ];

  static int getIndexForRoute(String route) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].route == route) return i;
    }
    return 0; // Default to dashboard
  }
}
