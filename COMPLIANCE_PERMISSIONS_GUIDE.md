# Compliance Permissions Guide

## Overview

This document outlines the comprehensive permission system for the compliance management features in the enterprise compliance tracker application. The system provides granular access control for compliance frameworks, requirements, and controls based on user roles and organizational hierarchy.

## Permission Structure

### Permission Model
- **Resource Types**: `ComplianceFramework`, `ComplianceRequirement`, `ComplianceControl`, `RiskDashboard`, `Api`
- **Actions**: `create`, `read`, `update`, `destroy`, `manage`, `assign`, `delegate`
- **Grantee Types**: `User` (direct permissions) or `Role` (role-based permissions)
- **Scope**: Organization-scoped with multi-tenancy support

### Permission Hierarchy

#### 1. Super Admin (admin@complianceapp.com)
- **Access Level**: Full system access
- **Compliance Permissions**:
  - `manage` all compliance frameworks, requirements, and controls
  - `manage` risk dashboard
  - `manage` API access
- **Scope**: Cross-organization access

#### 2. Organization Admin (admin@acme.com, admin@techstart.com)
- **Access Level**: Full organization access
- **Compliance Permissions**:
  - `manage` all compliance frameworks, requirements, and controls within organization
  - `read` all compliance data
  - `manage` risk dashboard
  - `manage` API access
- **Scope**: Organization-wide

#### 3. Department Admin (Legal Department)
- **Access Level**: Department-level management
- **Compliance Permissions**:
  - `manage` all compliance frameworks, requirements, and controls
  - `read` all compliance data
  - `manage` risk dashboard
  - `read` API access
- **Scope**: Organization-wide (legal oversight)

#### 4. Team Lead (Compliance Team)
- **Access Level**: Team-level management
- **Compliance Permissions**:
  - `manage` all compliance frameworks, requirements, and controls
  - `read` all compliance data
  - `manage` risk dashboard
  - `read` API access
- **Scope**: Organization-wide (compliance team)

#### 5. Unit Manager (Regulatory Monitoring)
- **Access Level**: Unit-level management
- **Compliance Permissions**:
  - `manage` all compliance frameworks, requirements, and controls
  - `read` all compliance data
  - `manage` risk dashboard
  - `read` API access
- **Scope**: Organization-wide (regulatory monitoring)

#### 6. Compliance Officer
- **Access Level**: Compliance oversight
- **Compliance Permissions**:
  - `read` all compliance frameworks, requirements, and controls
  - `update` compliance controls
  - `read` risk dashboard
  - `read` API access
- **Scope**: Organization-wide (read-only with control updates)

#### 7. Regular User
- **Access Level**: Basic access
- **Compliance Permissions**:
  - `read` all compliance frameworks, requirements, and controls
  - `read` risk dashboard
- **Scope**: Organization-wide (read-only)

## Seeded Users and Their Permissions

### Acme Corporation Users

#### 1. Super Admin (admin@complianceapp.com)
- **Password**: password123
- **Permissions**: Full system access across all organizations
- **Compliance Access**: Can manage all compliance data in all organizations

#### 2. Acme Admin (admin@acme.com)
- **Password**: password123
- **Permissions**: Full Acme Corporation access
- **Compliance Access**: Can manage all compliance frameworks, requirements, and controls

#### 3. Legal Department Admin (legal.admin@acme.com)
- **Password**: password123
- **Permissions**: Legal department management + compliance oversight
- **Compliance Access**: Full compliance management with legal focus

#### 4. Compliance Team Lead (compliance.lead@acme.com)
- **Password**: password123
- **Permissions**: Compliance team management
- **Compliance Access**: Full compliance management with operational focus

#### 5. Regulatory Monitoring Manager (monitoring.manager@acme.com)
- **Password**: password123
- **Permissions**: Regulatory monitoring unit management
- **Compliance Access**: Full compliance management with monitoring focus

#### 6. Compliance Officer (compliance.officer@acme.com)
- **Password**: password123
- **Permissions**: Compliance oversight and reporting
- **Compliance Access**: Read access to all compliance data, can update controls

#### 7. Regular User (user@acme.com)
- **Password**: password123
- **Permissions**: Basic organizational access
- **Compliance Access**: Read-only access to all compliance data

### TechStart Users

#### 1. TechStart Admin (admin@techstart.com)
- **Password**: password123
- **Permissions**: Full TechStart access
- **Compliance Access**: Can manage all compliance frameworks, requirements, and controls

#### 2. TechStart Compliance User (compliance@techstart.com)
- **Password**: password123
- **Permissions**: Compliance management
- **Compliance Access**: Read access to all compliance data, can create and update controls

## Role-Based Permissions

The system also supports role-based permissions that can be dynamically assigned:

### Acme Roles
- **Organization Admin Role**: Full compliance management
- **Department Admin Role**: Full compliance management
- **Team Lead Role**: Full compliance management
- **Unit Manager Role**: Full compliance management
- **Compliance Officer Role**: Read access + control updates
- **User Role**: Read-only access

### TechStart Roles
- **Organization Admin Role**: Full compliance management
- **Compliance Officer Role**: Read access + control updates

## Specific Framework Permissions

### Acme GDPR Framework
- **Legal Team**: Full management access
- **Compliance Team**: Full management access
- **Monitoring Unit**: Full management access
- **Compliance Officer**: Read access
- **Regular Users**: Read access

### Acme SOX Framework
- **Legal Team**: Full management access
- **Compliance Team**: Full management access
- **Monitoring Unit**: Full management access
- **Compliance Officer**: Read access
- **Regular Users**: Read access

### TechStart Software License Framework
- **TechStart Admin**: Full management access
- **Compliance User**: Full management access

## Risk Dashboard Access

### Acme Corporation
- **Management Access**: Super Admin, Org Admin, Legal Dept Admin, Compliance Team Lead, Monitoring Manager
- **Read Access**: Compliance Officer, Regular User

### TechStart
- **Management Access**: TechStart Admin
- **Read Access**: TechStart Compliance User

## API Access

### Acme Corporation
- **Full Access**: Super Admin, Org Admin
- **Read Access**: Legal Dept Admin, Compliance Team Lead, Compliance Officer

### TechStart
- **Full Access**: TechStart Admin
- **Read Access**: TechStart Compliance User

## Permission Checking in Controllers

The application uses Pundit for authorization with the following pattern:

```ruby
# In controllers
before_action :authorize_compliance_framework

def authorize_compliance_framework
  case action_name
  when 'index'
    authorize ComplianceFramework.new(organization: @organization), :index?
  when 'show'
    authorize @compliance_framework, :show?
  when 'new', 'create'
    authorize ComplianceFramework.new(organization: @organization), :create?
  when 'edit', 'update'
    authorize @compliance_framework, :update?
  when 'destroy'
    authorize @compliance_framework, :destroy?
  end
end
```

## Permission Checking in Views

```erb
<% if policy(ComplianceFramework.new(organization: @organization)).create? %>
  <%= link_to "New Framework", new_organization_compliance_framework_path(@organization) %>
<% end %>

<% if policy(@compliance_framework).update? %>
  <%= link_to "Edit", edit_organization_compliance_framework_path(@organization, @compliance_framework) %>
<% end %>
```

## Testing Permissions

To test the permission system:

1. **Login as different users** and navigate to compliance sections
2. **Verify access levels** match the defined permissions
3. **Check role assignments** in the roles management section
4. **Test API access** with different user credentials

## Permission Management

### Adding New Permissions
```ruby
# Create a new permission
Permission.create!(
  organization: organization,
  name: "Custom Permission",
  action: "read",
  resource_type: "ComplianceFramework",
  resource: specific_framework, # or nil for global
  grantee: user_or_role
)
```

### Checking Permissions Programmatically
```ruby
# Check if user has permission
Permission.user_has_permission?(user, "read", "ComplianceFramework")

# Check specific resource permission
Permission.user_has_permission?(user, "update", "ComplianceControl", specific_control)
```

## Security Considerations

1. **Multi-tenancy**: All permissions are organization-scoped
2. **Role-based access**: Permissions can be assigned to roles for dynamic access
3. **Resource-specific permissions**: Granular control over specific frameworks/requirements
4. **Conditional permissions**: Time-based and user-condition based permissions
5. **Audit trail**: All permission changes are tracked

## Troubleshooting

### Common Issues

1. **"Access Denied" errors**: Check user's organization and role assignments
2. **Missing permissions**: Verify permissions are created in seeds
3. **Role conflicts**: Ensure roles are properly scoped to organizations
4. **Policy errors**: Check that policies are properly configured

### Debugging Permissions

```ruby
# Check user's permissions
user.organization.permissions.for_user(user).pluck(:name, :action, :resource_type)

# Check role permissions
role.permissions.pluck(:name, :action, :resource_type)

# Test specific permission
Permission.user_has_permission?(user, "read", "ComplianceFramework")
```

This permission system provides comprehensive access control for the compliance management features while maintaining security and flexibility for different organizational structures. 