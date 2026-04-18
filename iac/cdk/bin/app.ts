#!/usr/bin/env node
import * as cdk from "aws-cdk-lib";
import { StartupFoundationStack } from "../lib/startup-stack";

const app = new cdk.App();
new StartupFoundationStack(app, "StartupFoundationStack", {
  env: { account: process.env.CDK_DEFAULT_ACCOUNT, region: "us-east-1" },
});
