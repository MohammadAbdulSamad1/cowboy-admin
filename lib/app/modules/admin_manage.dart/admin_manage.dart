// admin_management_controller.dart
import 'package:dedicated_cow_boy_admin/app/models/user_model.dart';
import 'package:dedicated_cow_boy_admin/app/modules/admin_manage.dart/view.dart';
import 'package:dedicated_cow_boy_admin/app/modules/auth/controller.dart';
import 'package:dedicated_cow_boy_admin/app/services/admin_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManagementController extends GetxController {
  final AdminService _adminService = AdminService.instance;
  final AuthController _authController = AuthController.instance;

  // Observables
  final RxList<AdminModel> admins = <AdminModel>[].obs;
  final RxList<AdminModel> filteredAdmins = <AdminModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedRole = 'all'.obs;
  final RxString selectedStatus = 'all'.obs;
  final Rx<AdminModel?> selectedAdmin = Rx<AdminModel?>(null);
  final RxBool showCreateDialog = false.obs;
  final RxBool showEditDialog = false.obs;
  final RxBool showPermissionsDialog = false.obs;

  // Form controllers
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> createFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> editFormKey = GlobalKey<FormState>();

  // Dropdown values
  final RxString selectedRoleForCreate = 'admin'.obs;
  final RxMap<String, dynamic> customPermissions = <String, dynamic>{}.obs;

  // Available roles
  final List<String> availableRoles = ['admin', 'moderator'];
  final List<String> statusOptions = ['all', 'active', 'inactive'];

  // Current user admin data
  Rx<AdminModel?> currentAdmin = Rx<AdminModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _getCurrentAdminData();
    _loadAdmins();
    _setupSearchListener();
  }

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    emailController.dispose();
    departmentController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  // Get current admin data
  Future<void> _getCurrentAdminData() async {
    final adminData = await _adminService.getCurrentAdminData();
    if (adminData != null) {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(_authController.firebaseUser.value!.uid)
              .get();

      currentAdmin.value = AdminModel.fromFirestore(docSnapshot);
    }
  }

  // Setup search listener
  void _setupSearchListener() {
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      _filterAdmins();
    });
  }

  // Load all admins
  Future<void> _loadAdmins() async {
    try {
      isLoading.value = true;
      final adminsList = await _adminService.getAllActiveAdmins();
      admins.value = adminsList;
      _filterAdmins();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load admins: ${e.toString()}',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Filter admins based on search and filters
  void _filterAdmins() {
    List<AdminModel> filtered = List.from(admins);

    // Search filter
    if (searchQuery.value.isNotEmpty) {
      filtered =
          filtered.where((admin) {
            return admin.displayName.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                admin.email.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                admin.department?.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ) ==
                    true;
          }).toList();
    }

    // Role filter
    if (selectedRole.value != 'all') {
      filtered =
          filtered.where((admin) => admin.role == selectedRole.value).toList();
    }

    // Status filter
    if (selectedStatus.value != 'all') {
      bool isActive = selectedStatus.value == 'active';
      filtered = filtered.where((admin) => admin.isActive == isActive).toList();
    }

    filteredAdmins.value = filtered;
  }

  // Check if current user can perform admin management actions
  bool canManageAdmins() {
    if (currentAdmin.value == null) return false;
    return _adminService.hasPermission(
      currentAdmin.value!,
      'admin_management',
      'write',
    );
  }

  bool canDeleteAdmins() {
    if (currentAdmin.value == null) return false;
    return _adminService.hasPermission(
      currentAdmin.value!,
      'admin_management',
      'delete',
    );
  }

  bool isSuperAdmin() {
    return currentAdmin.value?.role == 'super_admin';
  }

  // Create new admin
  Future<void> createAdmin() async {
    if (!createFormKey.currentState!.validate()) return;
    if (!canManageAdmins()) {
      Get.snackbar(
        'Access Denied',
        'You do not have permission to create admins',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      isCreating.value = true;

      final success = await _adminService.createNewAdmin(
        email: emailController.text.trim(),
        displayName: nameController.text.trim(),
        role: selectedRoleForCreate.value,
        department: departmentController.text.trim(),
        createdBy: _authController.firebaseUser.value!.uid,
      );

      if (success) {
        _clearCreateForm();
        showCreateDialog.value = false;
        await _loadAdmins(); // Refresh the list

        Get.snackbar(
          'Success',
          'Admin created successfully. Password reset email sent.',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to create admin',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create admin: ${e.toString()}',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isCreating.value = false;
    }
  }

  // Update admin
  Future<void> updateAdmin() async {
    if (!editFormKey.currentState!.validate()) return;
    if (!canManageAdmins() || selectedAdmin.value == null) return;

    try {
      isLoading.value = true;

      await FirebaseFirestore.instance
          .collection(FirestoreCollections.admins)
          .doc(selectedAdmin.value!.adminId)
          .update({
            'displayName': nameController.text.trim(),
            'department': departmentController.text.trim(),
            'phoneNumber': phoneController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Log the action
      await _adminService.createAdminLog(
        adminId: _authController.firebaseUser.value!.uid,
        email: _authController.firebaseUser.value!.email!,
        action: 'update_admin',
        resourceType: 'admin',
        resourceId: selectedAdmin.value!.adminId,
      );

      showEditDialog.value = false;
      await _loadAdmins();

      Get.snackbar(
        'Success',
        'Admin updated successfully',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update admin: ${e.toString()}',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle admin status
  Future<void> toggleAdminStatus(AdminModel admin) async {
    if (!canDeleteAdmins()) {
      Get.snackbar(
        'Access Denied',
        'You do not have permission to deactivate admins'
        ,    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (admin.adminId == _authController.firebaseUser.value!.uid) {
      Get.snackbar('Error', 'You cannot deactivate your own account',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),);
      return;
    }

    try {
      final bool newStatus = !admin.isActive;

      await FirebaseFirestore.instance
          .collection(FirestoreCollections.admins)
          .doc(admin.adminId)
          .update({
            'isActive': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!newStatus) {
        await _adminService.deactivateAdminSessions(admin.adminId);
      }

      await _adminService.createAdminLog(
        adminId: _authController.firebaseUser.value!.uid,
        email: _authController.firebaseUser.value!.email!,
        action: newStatus ? 'activate_admin' : 'deactivate_admin',
        resourceType: 'admin',
        resourceId: admin.adminId,
      );

      await _loadAdmins();

      Get.snackbar(
        'Success',
        'Admin ${newStatus ? 'activated' : 'deactivated'} successfully',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update admin status: ${e.toString()}',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Update admin permissions
  Future<void> updateAdminPermissions() async {
    if (!isSuperAdmin() || selectedAdmin.value == null) {
      Get.snackbar('Access Denied', 'Only super admins can modify permissions',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.admins)
          .doc(selectedAdmin.value!.adminId)
          .update({
            'permissions': customPermissions.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _adminService.createAdminLog(
        adminId: _authController.firebaseUser.value!.uid,
        email: _authController.firebaseUser.value!.email!,
        action: 'update_permissions',
        resourceType: 'admin',
        resourceId: selectedAdmin.value!.adminId,
      );

      showPermissionsDialog.value = false;
      await _loadAdmins();

      Get.snackbar(
        'Success',
        'Permissions updated successfully',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update permissions: ${e.toString()}',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Show create dialog
  void showCreateAdminDialog() {
    if (!canManageAdmins()) {
      Get.snackbar(
        'Access Denied',
        'You do not have permission to create admins',   snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    _clearCreateForm();
    showCreateDialog.value = true;
    Get.dialog(CreateAdminDialog(controller: this));
  }



  // Show edit dialog
  void showEditAdminDialog(AdminModel admin) {
    // if (!canManageAdmins()) {
    //   Get.snackbar(
    //     'Access Denied',
    //     'You do not have permission to edit admins',
    //   );
    //   return;
    // }
    selectedAdmin.value = admin;
    nameController.text = admin.displayName;
    emailController.text = admin.email;
    departmentController.text = admin.department ?? '';
    phoneController.text = admin.phoneNumber ?? '';
    showEditDialog.value = true;
  }

  // Show permissions dialog
  void showPermissionsAdminDialog(AdminModel admin) {
  
    selectedAdmin.value = admin;
    customPermissions.value = Map<String, dynamic>.from(admin.permissions);
    showPermissionsDialog.value = true;
  }

  // Update permission for a resource and action
  void updatePermission(String resource, String action, bool value) {
    if (customPermissions.value[resource] == null) {
      customPermissions.value[resource] = <String, dynamic>{};
    }
    customPermissions.value[resource][action] = value;
    customPermissions.refresh();
  }

  // Get permission value
  bool getPermissionValue(String resource, String action) {
    return customPermissions.value[resource]?[action] ?? false;
  }

  // Clear create form
  void _clearCreateForm() {
    nameController.clear();
    emailController.clear();
    departmentController.clear();
    phoneController.clear();
    selectedRoleForCreate.value = 'admin';
  }

  // Form validators
  String? nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? departmentValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Department is required';
    }
    return null;
  }

  // Filter methods
  void updateRoleFilter(String role) {
    selectedRole.value = role;
    _filterAdmins();
  }

  void updateStatusFilter(String status) {
    selectedStatus.value = status;
    _filterAdmins();
  }

  void clearFilters() {
    searchController.clear();
    selectedRole.value = 'all';
    selectedStatus.value = 'all';
    _filterAdmins();
  }

  // Get role display name
  String getRoleDisplayName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      default:
        return role.toUpperCase();
    }
  }

  // Get role color
  Color getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return const Color(0xFFF2B342);
      case 'moderator':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class AdminSetupScript {
  static Future<void> setupInitialAdmin() async {
    try {
      final AdminService adminService = AdminService.instance;

      // Initialize default roles
      await adminService.initializeDefaultRoles();

      // Create initial super admin
      await adminService.createInitialAdmin(
        email: 'arbaz@arbaz.com', // Change this to your email
        password: 'arbaz@arbaz.com', // Change this to a secure password
        displayName: 'Super Administrator',
        department: 'IT Administration',
      );

      print('✅ Admin system setup completed successfully!');
      print('📧 Login with: admin@yourcompany.com');
      print('🔑 Password: SuperAdmin123! (Change immediately after login)');
    } catch (e) {
      print('❌ Setup failed: $e');
    }
  }
}
