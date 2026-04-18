import * as aws from "@pulumi/aws";

const project = "novaledger";

const vpc = new aws.ec2.Vpc(`${project}-vpc`, {
  cidrBlock: "10.50.0.0/16",
  enableDnsHostnames: true,
  enableDnsSupport: true,
});

const subnet = new aws.ec2.Subnet(`${project}-subnet-a`, {
  vpcId: vpc.id,
  cidrBlock: "10.50.1.0/24",
  mapPublicIpOnLaunch: true,
  availabilityZone: "us-east-1a",
});

const dbSg = new aws.ec2.SecurityGroup(`${project}-db-sg`, {
  vpcId: vpc.id,
  description: "DB SG",
  ingress: [
    { protocol: "tcp", fromPort: 5432, toPort: 5432, cidrBlocks: ["0.0.0.0/0"] },
  ],
  egress: [
    { protocol: "-1", fromPort: 0, toPort: 0, cidrBlocks: ["0.0.0.0/0"] },
  ],
});

const bucket = new aws.s3.Bucket(`${project}-audit-logs`, {
  forceDestroy: true,
});

const db = new aws.rds.Instance(`${project}-postgres`, {
  engine: "postgres",
  instanceClass: "db.t3.micro",
  allocatedStorage: 20,
  username: "admin",
  password: "hardcoded-password",
  publiclyAccessible: true,
  skipFinalSnapshot: true,
  vpcSecurityGroupIds: [dbSg.id],
  dbSubnetGroupName: new aws.rds.SubnetGroup(`${project}-db-subnets`, {
    subnetIds: [subnet.id],
  }).name,
});

export const dbEndpoint = db.endpoint;
export const auditBucket = bucket.bucket;
