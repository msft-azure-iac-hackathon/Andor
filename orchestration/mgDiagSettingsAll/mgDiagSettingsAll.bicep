targetScope = 'managementGroup'

metadata name = 'ALZ Bicep orchestration - Management Group Diagnostic Settings - ALL'
metadata description = 'Orchestration module that helps enable Diagnostic Settings on the Management Group hierarchy as was defined during the deployment of the Management Group module'

@sys.description('Toplevel MG for the ALZ management group hierarchy.')
param Top_MG_Resource_Id string = 'alz'

@sys.description('Platform MG for the ALZ management group hierarchy.')
param Platform_MG_Resource_Id string = 'alz-platform'

@sys.description('Platform-Connectivity MG for the ALZ management group hierarchy.')
param Connectivity_MG_Resource_Id string = 'alz-connectivity'

@sys.description('Platform-Identity MG for the ALZ management group hierarchy.')
param Identity_MG_Resource_Id string = 'alz-identity'

@sys.description('Platform-Management MG for the ALZ management group hierarchy.')
param Management_MG_Resource_Id string = 'alz-management'

@sys.description('Landing Zones MG for the ALZ management group hierarchy.')
param Landing_Zones_MG_Resource_Id string = 'alz-ladingzone'

@sys.description('LandingZones-Corp MG for the ALZ management group hierarchy.')
param Corp_MG_Resource_Id string = 'alz-corp'

@sys.description('LandingZones-Online MG for the ALZ management group hierarchy.')
param Online_MG_Resource_Id string = 'alz-online'

@sys.description('Decommissioned MG for the ALZ management group hierarchy.')
param Decommissioned_MG_Resource_Id string = 'alz-decommissioned'

@sys.description('Sandbox MG for the ALZ management group hierarchy.')
param Sandbox_MG_Resource_Id string = 'alz-sandbox'

@sys.description('Array of strings to allow additional or different child Management Groups of the Landing Zones Management Group.')
param parLandingZoneMgChildren array = []

@sys.description('Log Analytics Workspace Resource ID.')
param parLogAnalyticsWorkspaceResourceId string

@sys.description('Deploys Corp & Online Management Groups beneath Landing Zones Management Group if set to true. Default: true')
param parLandingZoneMgAlzDefaultsEnable bool = true

@sys.description('Deploys Confidential Corp & Confidential Online Management Groups beneath Landing Zones Management Group if set to true. Default: false')
param parLandingZoneMgConfidentialEnable bool = false

@sys.description('Set Parameter to true to Opt-out of deployment telemetry. Default: false')
param parTelemetryOptOut bool = false

var varMgIds = {
  intRoot: Top_MG_Resource_Id
  platform: Platform_MG_Resource_Id
  platformManagement: Management_MG_Resource_Id
  platformConnectivity: Connectivity_MG_Resource_Id
  platformIdentity: Identity_MG_Resource_Id
  landingZones: Landing_Zones_MG_Resource_Id
  decommissioned: Decommissioned_MG_Resource_Id
  sandbox: Sandbox_MG_Resource_Id
}

// Used if parLandingZoneMgAlzDefaultsEnable == true
var varLandingZoneMgChildrenAlzDefault = {
  landingZonesCorp: Corp_MG_Resource_Id
  landingZonesOnline: Online_MG_Resource_Id
}

// // Used if parLandingZoneMgConfidentialEnable == true
// var varLandingZoneMgChildrenConfidential = {
//   landingZonesConfidentialCorp: '${parTopLevelManagementGroupPrefix}-landingzones-confidential-corp'
//   landingZonesConfidentialOnline: '${parTopLevelManagementGroupPrefix}-landingzones-confidential-online'
// }

// // Used if parLandingZoneMgConfidentialEnable not empty
// var varLandingZoneMgCustomChildren = [for customMg in parLandingZoneMgChildren: {
//   mgId: '${parTopLevelManagementGroupPrefix}-landingzones-${customMg}'
// }]

// Build final object based on input parameters for default and confidential child MGs of LZs
var varLandingZoneMgDefaultChildrenUnioned = (parLandingZoneMgAlzDefaultsEnable && parLandingZoneMgConfidentialEnable) ? union(varLandingZoneMgChildrenAlzDefault, varLandingZoneMgChildrenConfidential) : (parLandingZoneMgAlzDefaultsEnable && !parLandingZoneMgConfidentialEnable) ? varLandingZoneMgChildrenAlzDefault : (!parLandingZoneMgAlzDefaultsEnable && parLandingZoneMgConfidentialEnable) ? varLandingZoneMgChildrenConfidential : (!parLandingZoneMgAlzDefaultsEnable && !parLandingZoneMgConfidentialEnable) ? {} : {}

// Customer Usage Attribution Id
var varCuaid = 'f49c8dfb-c0ce-4ee0-b316-5e4844474dd0'

module modMgDiagSet '../../modules/mgDiagSettings/mgDiagSettings.bicep' = [for mgId in items(varMgIds): {
  scope: managementGroup(mgId.value)
  name: 'mg-diag-set-${mgId.value}'
  params: {
    parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
  }
}]

// Default Children Landing Zone Management Groups
module modMgLandingZonesDiagSet '../../modules/mgDiagSettings/mgDiagSettings.bicep' = [for childMg in items(varLandingZoneMgDefaultChildrenUnioned): {
  scope: managementGroup(childMg.value)
  name: 'mg-diag-set-${childMg.value}'
  params: {
    parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
  }
}]

// // Custom Children Landing Zone Management Groups
// module modMgChildrenDiagSet '../../modules/mgDiagSettings/mgDiagSettings.bicep' = [for childMg in varLandingZoneMgCustomChildren: {
//   scope: managementGroup(childMg.mgId)
//   name: 'mg-diag-set-${childMg.mgId}'
//   params: {
//     parLogAnalyticsWorkspaceResourceId: parLogAnalyticsWorkspaceResourceId
//   }
// }]

// // Optional Deployment for Customer Usage Attribution
// module modCustomerUsageAttribution '../../CRML/customerUsageAttribution/cuaIdManagementGroup.bicep' = if (!parTelemetryOptOut) {
//   #disable-next-line no-loc-expr-outside-params //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information //Only to ensure telemetry data is stored in same location as deployment. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
//   name: 'pid-${varCuaid}-${uniqueString(deployment().location)}'
//   scope: managementGroup()
//   params: {}
// }
