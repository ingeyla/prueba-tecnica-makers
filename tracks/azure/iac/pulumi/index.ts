import * as azure from "@pulumi/azure-native";

const rg = new azure.resources.ResourceGroup("novaledger-azure-rg", {
  resourceGroupName: "novaledger-azure-rg",
  location: "eastus",
});

const cluster = new azure.containerservice.ManagedCluster("novaledger-aks", {
  resourceGroupName: rg.name,
  location: rg.location,
  dnsPrefix: "novaledgeraks",
  identity: { type: "SystemAssigned" },
  agentPoolProfiles: [{
    name: "default",
    count: 1,
    vmSize: "Standard_B2s",
    mode: "System",
    osType: "Linux",
    type: "VirtualMachineScaleSets",
  }],
  apiServerAccessProfile: {
    enablePrivateCluster: false,
  },
});

const postgres = new azure.dbforpostgresql.FlexibleServer("novaledger-db", {
  resourceGroupName: rg.name,
  location: rg.location,
  version: "15",
  administratorLogin: "admin",
  administratorLoginPassword: "hardcoded-password",
  sku: { name: "B_Standard_B1ms", tier: "Burstable" },
  backup: { backupRetentionDays: 7 },
});

export const clusterName = cluster.name;
export const postgresServer = postgres.name;
