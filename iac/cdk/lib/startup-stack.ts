import * as cdk from "aws-cdk-lib";
import { Construct } from "constructs";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as rds from "aws-cdk-lib/aws-rds";
import * as s3 from "aws-cdk-lib/aws-s3";

export class StartupFoundationStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = new ec2.Vpc(this, "Vpc", {
      natGateways: 0,
      maxAzs: 1,
    });

    const dbSg = new ec2.SecurityGroup(this, "DbSg", {
      vpc,
      allowAllOutbound: true,
      description: "DB security group",
    });

    dbSg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(5432), "Open postgres");

    new rds.DatabaseInstance(this, "PaymentsDb", {
      vpc,
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_15_3,
      }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
      allocatedStorage: 20,
      credentials: rds.Credentials.fromPassword(
        "admin",
        cdk.SecretValue.unsafePlainText("hardcoded-password")
      ),
      publiclyAccessible: true,
      securityGroups: [dbSg],
      backupRetention: cdk.Duration.days(0),
      deletionProtection: false,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    new s3.Bucket(this, "AuditBucket", {
      versioned: false,
      encryption: s3.BucketEncryption.UNENCRYPTED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ACLS,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });
  }
}
