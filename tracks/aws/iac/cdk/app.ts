import * as cdk from "aws-cdk-lib";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as rds from "aws-cdk-lib/aws-rds";
import { Construct } from "constructs";

class AwsTrackStack extends cdk.Stack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    const vpc = new ec2.Vpc(this, "Vpc", { maxAzs: 1, natGateways: 0 });

    const db = new rds.DatabaseInstance(this, "Db", {
      engine: rds.DatabaseInstanceEngine.postgres({ version: rds.PostgresEngineVersion.VER_15_3 }),
      vpc,
      publiclyAccessible: true,
      credentials: rds.Credentials.fromPassword(
        "admin",
        cdk.SecretValue.unsafePlainText("hardcoded-password")
      ),
      deletionProtection: false,
      backupRetention: cdk.Duration.days(0),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
    });

    new cdk.CfnOutput(this, "DbEndpoint", { value: db.dbInstanceEndpointAddress });
  }
}

const app = new cdk.App();
new AwsTrackStack(app, "AwsTrackStack");
