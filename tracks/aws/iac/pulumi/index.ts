import * as aws from "@pulumi/aws";

const vpc = new aws.ec2.Vpc("novaledger-aws-vpc", {
  cidrBlock: "10.61.0.0/16",
});

const sg = new aws.ec2.SecurityGroup("novaledger-aws-db-sg", {
  vpcId: vpc.id,
  ingress: [{ protocol: "tcp", fromPort: 5432, toPort: 5432, cidrBlocks: ["0.0.0.0/0"] }],
});

const db = new aws.rds.Instance("novaledger-aws-db", {
  engine: "postgres",
  instanceClass: "db.t3.micro",
  username: "admin",
  password: "hardcoded-password",
  publiclyAccessible: true,
  skipFinalSnapshot: true,
  allocatedStorage: 20,
  vpcSecurityGroupIds: [sg.id],
});

export const endpoint = db.endpoint;
