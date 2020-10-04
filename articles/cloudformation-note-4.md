---
title: CFnでVPCを作ったり消したりする～ファイル分割パターン２～
emoji: 📝
type: tech
topics: [CloudFormation]
published: true
---

# CFnでVPCを作ったり消したりする～ファイル分割方法２つめ～

- CrossReferenceという方法らしい
- OutputsにてExportsをくっつけると、グローバル変数っぽくなるため、それをImportする

```yaml
Outputs:
  VpcId:
    Value: !Ref VPC
    Export:
      Name: GlobalBasicVpcId
```

別ファイル（完全に独立した別スタック）からImporValueで読み込める

```yaml
Properties:
  VpcId: !ImportValue GlobalBasicVpcId
```

#### ポイント

- S3を別途作らなくていい
- creat-stackを複数回やる
- もしExportsするものがupdate-stack毎にかわるものだったら、それに依存するものは一度削除して作り直す必要があるらしい（意外とネックかも）

## 作成

VPC

```bash
$ aws cloudformation create-stack --stack-name スタック名１ --template-body file://main-vpc.yaml --parameters ParameterKey=Env,ParameterValue=dev
```

VPC public subnets

```bash
$ aws cloudformation create-stack --stack-name スタック名２ --template-body file://main-public-subnets.yaml --parameters ParameterKey=Env,ParameterValue=dev
```

VPC intra subnets

```bash
$ aws cloudformation create-stack --stack-name スタック名３ --template-body file://main-intra-subnets.yaml --parameters ParameterKey=Env,ParameterValue=dev
```

main-vpc.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "VPC only"
##############################################################################
# パラメータ
##############################################################################
Parameters:
  Env:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - prd
      - stg
    Description: Enter the environment. (prd/dev/stg)

##############################################################################
# リソース
##############################################################################
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-vpc", !Ref Env ] ]

##############################################################################
# Output
##############################################################################
Outputs:
  VpcId:
    Value: !Ref VPC
    Export:
      Name: GlobalBasicVpcId
  DefaultSecurityGroupId:
    Value: !GetAtt VPC.DefaultSecurityGroup
```

main-public-subnets.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "3 public subnets"

##############################################################################
# パラメータ
##############################################################################
Parameters:
  Env:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - prd
      - stg
    Description: Enter the environment. (prd/dev/stg)

##############################################################################
# リソース
##############################################################################
Resources:
  VPCSubnetPubA:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1a
      CidrBlock: 10.0.0.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-pub-subnet-a", !Ref Env ] ]
      VpcId: !ImportValue GlobalBasicVpcId
  VPCSubnetPubC:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1c
      CidrBlock: 10.0.16.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-pub-subnet-c", !Ref Env ] ]
      VpcId: !ImportValue GlobalBasicVpcId
  VPCSubnetPubD:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1d
      CidrBlock: 10.0.32.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-pub-subnet-d", !Ref Env ] ]
      VpcId: !ImportValue GlobalBasicVpcId
  ##############################################################################
  # Internet Gateway
  ##############################################################################
  IGW:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-igw", !Ref Env ] ]
  AttachIGW:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId: !Ref IGW
      VpcId: !ImportValue GlobalBasicVpcId
  ##############################################################################
  # Route Table(For Public)
  ##############################################################################
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !ImportValue GlobalBasicVpcId
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-rt", !Ref Env ] ]
  PublicRoute:
    Type: AWS::EC2::Route
    Properties:
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref IGW
      RouteTableId: !Ref PublicRouteTable
  PublicRouteTableAssociationA:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref VPCSubnetPubA
  PublicRouteTableAssociationC:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref VPCSubnetPubC
  PublicRouteTableAssociationD:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref VPCSubnetPubD
```

main-intra-subnets.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "3 intra subnets"

##############################################################################
# パラメータ
##############################################################################
Parameters:
  Env:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - prd
      - stg
    Description: Enter the environment. (prd/dev/stg)

##############################################################################
# リソース
##############################################################################
Resources:
  ##############################################################################
  # VPC Subnet(Intra)
  ##############################################################################
  VPCSubnetIntraA:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1a
      CidrBlock: 10.0.48.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-intra-subnet-a", !Ref Env ] ]
      VpcId: !ImportValue GlobalBasicVpcId
  VPCSubnetIntraC:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1c
      CidrBlock: 10.0.64.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-intra-subnet-c", !Ref Env ] ]
      VpcId: !ImportValue GlobalBasicVpcId
  VPCSubnetIntraD:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1d
      CidrBlock: 10.0.80.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-intra-subnet-d", !Ref Env ] ]
      VpcId: !ImportValue GlobalBasicVpcId
  ##############################################################################
  # Route table(For Intra)
  ##############################################################################
  IntraRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !ImportValue GlobalBasicVpcId
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-intra-rt", !Ref Env ] ]
  IntraRouteTableAssociationA:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref IntraRouteTable
      SubnetId: !Ref VPCSubnetIntraA
  IntraRouteTableAssociationC:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref IntraRouteTable
      SubnetId: !Ref VPCSubnetIntraC
  IntraRouteTableAssociationD:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref IntraRouteTable
      SubnetId: !Ref VPCSubnetIntraD
```
