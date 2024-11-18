param principalIds array = []
param roles array = []

var principalRolesMapping = [
  for principalId in principalIds: map(roles, role => { principalId: principalId, role: role })
]

var flattenedPrincipalRoles = flatten(principalRolesMapping)

module roleAssignment 'role.bicep' = [
  for principalRoleMapping in flattenedPrincipalRoles: {
    name: 'role-assignment-${uniqueString(principalRoleMapping.principalId, principalRoleMapping.role)}'
    params: {
      principalId: principalRoleMapping.principalId
      roleDefinitionId: principalRoleMapping.role
      principalType: 'Group'
    }
  }
]
