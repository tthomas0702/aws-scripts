#!/bin/bash

aws --region us-west-2 ec2 describe-security-groups --query 'SecurityGroups[*].GroupName'


