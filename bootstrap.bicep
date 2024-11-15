@minLength(1)
@maxLength(64)
@description('Prefix for all resources')
param hackName string

@minLength(1)
@description('Primary location for all resources')
param location string

param tags object = {}

var abbrs = loadJsonContent('abbreviations.json')
var roles = loadJsonContent('azure_roles.json')

var resourceToken = toLower(uniqueString(subscription().id, hackName, location))
