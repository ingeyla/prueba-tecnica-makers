import { App, TerraformStack } from "cdktf";
import { Construct } from "constructs";
import { AzurermProvider, ResourceGroup, KubernetesCluster } from "@cdktf/provider-azurerm";

class AzureTrackStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    new AzurermProvider(this, "azurerm", { features: {} });

    const rg = new ResourceGroup(this, "rg", {
      name: "novaledger-cdktf-rg",
      location: "East US",
    });

    new KubernetesCluster(this, "aks", {
      name: "novaledger-cdktf-aks",
      location: rg.location,
      resourceGroupName: rg.name,
      dnsPrefix: "novaledgercdktf",
      defaultNodePool: {
        name: "default",
        nodeCount: 1,
        vmSize: "Standard_B2s",
      },
      identity: {
        type: "SystemAssigned",
      },
      privateClusterEnabled: false,
      localAccountDisabled: false,
    });
  }
}

const app = new App();
new AzureTrackStack(app, "AzureTrackStack");
app.synth();
