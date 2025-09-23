// admin_management_screen.dart
import 'package:dedicated_cow_boy_admin/app/models/user_model.dart';
import 'package:dedicated_cow_boy_admin/app/modules/admin_manage.dart/admin_manage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({Key? key}) : super(key: key);

  // Theme Colors
  static const Color primaryColor = Color(0xFF364C63);
  static const Color secondaryColor = Color(0xFFF2B342);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Colors.black54;
  static const Color lightGrayColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFE8EAED);

  @override
  Widget build(BuildContext context) {
    final AdminManagementController controller = Get.put(
      AdminManagementController(),
    );

    return Scaffold(
      backgroundColor: lightGrayColor,
      body: SingleChildScrollView(
        child: Column(
          children: [_buildHeader(controller), _buildContent(controller)],
        ),
      ),
    );
  }

  Widget _buildHeader(AdminManagementController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 28,
                        color: backgroundColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Admin Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: backgroundColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () =>
                        controller.canManageAdmins()
                            ? ElevatedButton.icon(
                              onPressed: controller.showCreateAdminDialog,
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: const Text(
                                'Create Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFF2B342),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                            : const SizedBox(),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 36,
                  color: backgroundColor,
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Management',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: backgroundColor,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage administrators and their permissions',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFB0BEC5),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () =>
                    controller.canManageAdmins()
                        ? ElevatedButton.icon(
                          onPressed: controller.showCreateAdminDialog,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Create Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF2B342),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                        : const SizedBox(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(AdminManagementController controller) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _buildFiltersCard(controller),
          const SizedBox(height: 24),
          _buildDataTableCard(controller),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(AdminManagementController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet =
                  constraints.maxWidth > 768 && constraints.maxWidth <= 1024;
              final isDesktop = constraints.maxWidth > 1024;
              final isMobile = constraints.maxWidth <= 768;

              if (isDesktop) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: _buildSearchField(controller)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildRoleFilter(controller)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildStatusFilter(controller)),
                    const SizedBox(width: 20),
                    SizedBox(width: 140, child: _buildClearButton(controller)),
                  ],
                );
              } else if (isTablet) {
                return Column(
                  children: [
                    _buildSearchField(controller),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildRoleFilter(controller)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatusFilter(controller)),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 140,
                          child: _buildClearButton(controller),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSearchField(controller),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildRoleFilter(controller)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatusFilter(controller)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: _buildClearButton(controller),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AdminManagementController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        color: surfaceColor,
      ),
      child: TextField(
        controller: controller.searchController,
        style: const TextStyle(
          color: textPrimaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search admins by name or email...',
          hintStyle: const TextStyle(color: textSecondaryColor, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: textSecondaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleFilter(AdminManagementController controller) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          color: surfaceColor,
        ),
        child: DropdownButtonFormField<String>(
          value: controller.selectedRole.value,
          style: const TextStyle(
            color: textPrimaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            labelText: 'Role',
            labelStyle: TextStyle(
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            prefixIcon: Icon(
              Icons.admin_panel_settings,
              color: textSecondaryColor,
            ),
          ),
          items:
              ['all', ...controller.availableRoles, 'super_admin']
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(
                        role == 'all'
                            ? 'All Roles'
                            : controller.getRoleDisplayName(role),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (value) => controller.updateRoleFilter(value!),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(AdminManagementController controller) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          color: surfaceColor,
        ),
        child: DropdownButtonFormField<String>(
          value: controller.selectedStatus.value,
          style: const TextStyle(
            color: textPrimaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            labelText: 'Status',
            labelStyle: TextStyle(
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            prefixIcon: Icon(Icons.toggle_on, color: textSecondaryColor),
          ),
          items:
              controller.statusOptions
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        status == 'all' ? 'All Status' : status.toUpperCase(),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (value) => controller.updateStatusFilter(value!),
        ),
      ),
    );
  }

  Widget _buildClearButton(AdminManagementController controller) {
    return ElevatedButton.icon(
      onPressed: controller.clearFilters,
      icon: const Icon(Icons.clear_all, size: 18, color: backgroundColor),
      label: const Text(
        'Clear',
        style: TextStyle(
          color: backgroundColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: textSecondaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDataTableCard(AdminManagementController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Admins List',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: secondaryColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    '${controller.filteredAdmins.length} admins',
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 600,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: secondaryColor),
                );
              }

              if (controller.filteredAdmins.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.people_outline,
                          size: 64,
                          color: textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No admins found',
                        style: TextStyle(
                          fontSize: 20,
                          color: textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try adjusting your filters or create a new admin',
                        style: TextStyle(
                          fontSize: 15,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1024) {
                    return _buildDesktopDataTable(controller);
                  } else {
                    return _buildMobileAdminsList(controller);
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDataTable(AdminManagementController controller) {
    return DataTable2(
      columnSpacing: 24,
      horizontalMargin: 0,
      minWidth: 1100,
      headingRowColor: MaterialStateProperty.all(surfaceColor),
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: primaryColor,
        fontSize: 15,
      ),
      dataRowHeight: 80,
      headingRowHeight: 60,
      dataTextStyle: const TextStyle(
        color: textPrimaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      columns: const [
        DataColumn2(label: Text('Admin Details'), size: ColumnSize.L),
        DataColumn2(label: Text('Role'), size: ColumnSize.S),
        DataColumn2(label: Text('Department'), size: ColumnSize.M),
        DataColumn2(label: Text('Status'), size: ColumnSize.S),
        DataColumn2(label: Text('Last Login'), size: ColumnSize.M),
        DataColumn2(
          label: Text('Actions'),
          size: ColumnSize.M,
          fixedWidth: 220,
        ),
      ],
      rows:
          controller.filteredAdmins.map((admin) {
            return DataRow2(
              cells: [
                DataCell(_buildAdminInfo(admin)),
                DataCell(_buildRoleBadge(admin.role, controller)),
                DataCell(
                  Text(
                    admin.department ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: textPrimaryColor,
                    ),
                  ),
                ),
                DataCell(_buildStatusBadge(admin.isActive)),
                DataCell(
                  Text(
                    admin.lastLogin != null
                        ? _formatDate(admin.lastLogin!)
                        : 'Never',
                    style: const TextStyle(color: textSecondaryColor),
                  ),
                ),
                DataCell(_buildActionButtons(admin, controller)),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildMobileAdminsList(AdminManagementController controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.filteredAdmins.length,
      padding: const EdgeInsets.all(0),
      itemBuilder: (context, index) {
        final admin = controller.filteredAdmins[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildAdminInfo(admin)),
                  _buildStatusBadge(admin.isActive),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildRoleBadge(admin.role, controller),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      admin.department ?? 'N/A',
                      style: const TextStyle(
                        color: textSecondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Last Login: ${admin.lastLogin != null ? _formatDate(admin.lastLogin!) : 'Never'}',
                style: const TextStyle(color: textSecondaryColor, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _buildActionButtons(admin, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminInfo(AdminModel admin) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              admin.displayName.isNotEmpty
                  ? admin.displayName.substring(0, 1).toUpperCase()
                  : 'A',
              style: const TextStyle(
                color: backgroundColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                admin.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                admin.email,
                style: const TextStyle(color: textSecondaryColor, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role, AdminManagementController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        controller.getRoleDisplayName(role),
        style: const TextStyle(
          color: backgroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? secondaryColor : textSecondaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: isActive ? primaryColor : backgroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    AdminModel admin,
    AdminManagementController controller,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildActionButton(
          icon: Icons.edit_outlined,
          color: secondaryColor,
          tooltip: 'Edit Admin',
          onPressed: () => _showEditAdminDialog(admin, controller),
        ),

        _buildActionButton(
          icon:
              admin.isActive
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
          color: textSecondaryColor,
          tooltip: admin.isActive ? 'Deactivate' : 'Activate',
          onPressed: () => _showDeactivateDialog(admin, controller),
        ),
      ],
    );
  }

  void _showEditAdminDialog(
    AdminModel admin,
    AdminManagementController controller,
  ) {
    // Pre-populate form fields with existing admin data
    controller.nameController.text = admin.displayName;
    controller.emailController.text = admin.email;
    controller.departmentController.text = admin.department ?? '';
    controller.phoneController.text = admin.phoneNumber ?? '';

    // Set selected admin for editing
    controller.selectedAdmin.value = admin;

    Get.dialog(
      EditAdminDialog(controller: controller),
      barrierDismissible: false,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 18),
        tooltip: tooltip,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  void _showDeactivateDialog(
    AdminModel admin,
    AdminManagementController controller,
  ) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (admin.isActive ? textSecondaryColor : secondaryColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  admin.isActive
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                  size: 48,
                  color: admin.isActive ? textSecondaryColor : secondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                admin.isActive ? 'Deactivate Admin' : 'Activate Admin',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                admin.isActive
                    ? 'Are you sure you want to deactivate ${admin.displayName}? They will be immediately logged out and unable to access the system.'
                    : 'Are you sure you want to activate ${admin.displayName}? They will regain access to the system.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textSecondaryColor,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.toggleAdminStatus(admin);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            admin.isActive
                                ? textSecondaryColor
                                : secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        admin.isActive ? 'Deactivate' : 'Activate',
                        style: TextStyle(
                          color:
                              admin.isActive ? backgroundColor : primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// Enhanced Create Admin Dialog Widget
class CreateAdminDialog extends StatelessWidget {
  final AdminManagementController controller;

  const CreateAdminDialog({Key? key, required this.controller})
    : super(key: key);

  // Theme Colors
  static const Color primaryColor = Color(0xFF364C63);
  static const Color secondaryColor = Color(0xFFF2B342);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Colors.black54;
  static const Color borderColor = Color(0xFFE8EAED);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 580 : double.infinity,
        constraints: const BoxConstraints(maxHeight: 750),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Form(
          key: controller.createFormKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: secondaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Text(
                        'Create New Admin',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: textSecondaryColor),
                      style: IconButton.styleFrom(
                        backgroundColor: surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                _buildInputField(
                  controller: controller.nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: controller.nameValidator,
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  controller: controller.emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  validator: controller.emailValidator,
                  keyboardType: TextInputType.emailAddress,
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  controller: controller.departmentController,
                  label: 'Department',
                  icon: Icons.business_outlined,
                  validator: controller.departmentValidator,
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  controller: controller.phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),

                Obx(
                  () => _buildDropdownField(
                    value: controller.selectedRoleForCreate.value,
                    label: 'Role',
                    icon: Icons.admin_panel_settings_outlined,
                    items:
                        controller.availableRoles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(
                                  controller.getRoleDisplayName(role),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) =>
                            controller.selectedRoleForCreate.value = value!,
                    isRequired: true,
                  ),
                ),
                const SizedBox(height: 28),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'A password reset email will be sent to the admin\'s email address for account setup.',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed:
                              controller.isCreating.value
                                  ? null
                                  : controller.createAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            disabledBackgroundColor: surfaceColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child:
                              controller.isCreating.value
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Create Admin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: textSecondaryColor, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            color: enabled ? backgroundColor : surfaceColor,
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            enabled: enabled,
            style: const TextStyle(
              color: textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: const TextStyle(color: textSecondaryColor),
              prefixIcon: Icon(icon, color: textSecondaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: textSecondaryColor, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            color: backgroundColor,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            style: const TextStyle(
              color: textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Select $label',
              hintStyle: const TextStyle(color: textSecondaryColor),
              prefixIcon: Icon(icon, color: textSecondaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// Enhanced Edit Admin Dialog Widget
class EditAdminDialog extends StatelessWidget {
  final AdminManagementController controller;

  const EditAdminDialog({Key? key, required this.controller}) : super(key: key);

  // Theme Colors
  static const Color primaryColor = Color(0xFF364C63);
  static const Color secondaryColor = Color(0xFFF2B342);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Colors.black54;
  static const Color borderColor = Color(0xFFE8EAED);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 580 : double.infinity,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Form(
          key: controller.editFormKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Text(
                        'Edit Admin',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: textSecondaryColor),
                      style: IconButton.styleFrom(
                        backgroundColor: surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                _buildInputField(
                  controller: controller.emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  enabled: false,
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  controller: controller.nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: controller.nameValidator,
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  controller: controller.departmentController,
                  label: 'Department',
                  icon: Icons.business_outlined,
                  validator: controller.departmentValidator,
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  controller: controller.phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 36),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed:
                              controller.isLoading.value
                                  ? null
                                  : controller.updateAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            disabledBackgroundColor: surfaceColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child:
                              controller.isLoading.value
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        backgroundColor,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Update Admin',
                                    style: TextStyle(
                                      color: backgroundColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: textSecondaryColor, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            color: enabled ? backgroundColor : surfaceColor,
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? textPrimaryColor : textSecondaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: enabled ? 'Enter $label' : label,
              hintStyle: const TextStyle(color: textSecondaryColor),
              prefixIcon: Icon(icon, color: textSecondaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Enhanced Permissions Dialog Widget
class PermissionsDialog extends StatelessWidget {
  final AdminManagementController controller;

  const PermissionsDialog({Key? key, required this.controller})
    : super(key: key);

  // Theme Colors
  static const Color primaryColor = Color(0xFF364C63);
  static const Color secondaryColor = Color(0xFFF2B342);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Colors.black54;
  static const Color borderColor = Color(0xFFE8EAED);

  final List<Map<String, String>> resources = const [
    {'key': 'users', 'name': 'User Management'},
    {'key': 'content', 'name': 'Content Management'},
    {'key': 'analytics', 'name': 'Analytics'},
    {'key': 'settings', 'name': 'Settings'},
    {'key': 'admin_management', 'name': 'Admin Management'},
    {'key': 'logs', 'name': 'Activity Logs'},
  ];

  final List<Map<String, String>> actions = const [
    {'key': 'read', 'name': 'Read'},
    {'key': 'write', 'name': 'Write'},
    {'key': 'delete', 'name': 'Delete'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width > 800 ? 800 : double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.security_outlined,
                      color: backgroundColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Permissions',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: backgroundColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Obx(
                          () => Text(
                            controller.selectedAdmin.value?.displayName ?? '',
                            style: const TextStyle(
                              color: Color(0xFFB0BEC5),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: backgroundColor),
                    style: IconButton.styleFrom(
                      backgroundColor: backgroundColor.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                border: Border(
                                  bottom: BorderSide(color: borderColor),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Resource',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  ...actions.map(
                                    (action) => Expanded(
                                      child: Text(
                                        action['name']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Permission rows
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children:
                                      resources
                                          .map(
                                            (resource) =>
                                                _buildPermissionRow(resource),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: controller.updateAdminPermissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Update Permissions',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(Map<String, String> resource) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  resource['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...actions.map(
            (action) => Expanded(
              child: Center(
                child: Obx(
                  () => Transform.scale(
                    scale: 1.3,
                    child: Checkbox(
                      value: controller.getPermissionValue(
                        resource['key']!,
                        action['key']!,
                      ),
                      onChanged:
                          (value) => controller.updatePermission(
                            resource['key']!,
                            action['key']!,
                            value ?? false,
                          ),
                      activeColor: secondaryColor,
                      checkColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
