import { App, TerraformStack } from "cdktf";
import { Construct } from "constructs";
import { GoogleProvider, ContainerCluster, SqlDatabaseInstance } from "@cdktf/provider-google";

class GcpTrackStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    new GoogleProvider(this, "google", {
      project: "replace-project-id",
      region: "us-central1",
    });

    new ContainerCluster(this, "gke", {
      name: "novaledger-cdktf-gke",
      location: "us-central1",
      initialNodeCount: 1,
      releaseChannel: { channel: "RAPID" },
    });

    new SqlDatabaseInstance(this, "db", {
      name: "novaledger-cdktf-db",
      region: "us-central1",
      databaseVersion: "POSTGRES_15",
      settings: {
        tier: "db-f1-micro",
        ipConfiguration: {
          ipv4Enabled: true,
          requireSsl: false,
        },
      },
      deletionProtection: false,
    });
  }
}

const app = new App();
new GcpTrackStack(app, "GcpTrackStack");
app.synth();
