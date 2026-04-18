import * as gcp from "@pulumi/gcp";

const network = new gcp.compute.Network("novaledger-gcp-vpc", {
  autoCreateSubnetworks: false,
});

const subnet = new gcp.compute.Subnetwork("novaledger-gcp-subnet", {
  ipCidrRange: "10.71.1.0/24",
  region: "us-central1",
  network: network.id,
});

const cluster = new gcp.container.Cluster("novaledger-gke", {
  location: "us-central1",
  network: network.name,
  subnetwork: subnet.name,
  removeDefaultNodePool: true,
  initialNodeCount: 1,
  releaseChannel: { channel: "RAPID" },
});

const db = new gcp.sql.DatabaseInstance("novaledger-sql", {
  region: "us-central1",
  databaseVersion: "POSTGRES_15",
  settings: {
    tier: "db-f1-micro",
    ipConfiguration: {
      ipv4Enabled: true,
      authorizedNetworks: [{ value: "0.0.0.0/0" }],
      requireSsl: false,
    },
    backupConfiguration: { enabled: false },
  },
  deletionProtection: false,
});

new gcp.sql.User("admin", {
  instance: db.name,
  name: "admin",
  password: "hardcoded-password",
});

export const clusterName = cluster.name;
