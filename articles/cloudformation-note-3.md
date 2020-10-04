---
title: CFnでVPCを作ったり消したりする～ファイル分割パターン１～
emoji: 📝
type: tech
topics: [CloudFormation]
published: true
---

- Outputs.hogeを利用するパターン

## Outputsセクション

公式ドキュメントの「構文」がわかりやすい
[CloudFormation > ユーザーガイド > 出力 > 構文](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html#outputs-section-syntax)

```yaml
Outputs:
  論理ID:
    Description: Information about the value
    Value: CFn側の変数
    Export:
      Name: 出力する時の変数名
```

## パブリックサブネット３つ、イントラサブネット３つ

### ネストテンプレートの利用（スタックが複数あり、親子関係がある）

親：main.yaml
子：残り

#### 構成

```
main.yaml
├── vpc.yaml
├── public-subnet.yaml
└── intra-subnet.yaml
```

![](https://i.imgur.com/OJMOZWW.png)


#### ポイント

- 一時的なS3を用意し、aws cloudformation packageコマンドでuploadすると、いい感じのtemp-output.yamlができる。これを利用する
- 実行したら一時的なS3バケットやtemp-output.yamlを削除する
- --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPANDというオプションが別途必要

#### デプロイまでの流れ

1. S3バケットの作成

```bash
S3バケットの作成
$ aws s3api create-bucket --bucket TEMP_S3バケット名 --create-bucket-configuration LocationConstraint=ap-northeast-1
```

2. uploadしてoutput.yamlの確認

```bash
$ aws cloudformation package --template-file ./main.yaml --s3-bucket TEMP_S3バケット名 --output-template-file output.yaml
$ cat output.yaml
```

3. output.yamlをcreate-stackする

```bash
$ aws cloudformation create-stack --stack-name スタック名 --template-body file://output.yaml --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND　--paramete  ParameterKey=Env,ParameterValue=dev
```

4. stackがデプロイされるのを確認する
5. 一時的に作ったS3バケットとoutput.yamlを削除

```bash
$ aws s3 rb s3://TEMP_S3バケット名 --force
$ rm $(CFN_OUTPUT_FILE_NAME)
```

main.yaml
```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "3 public subnets and 3 intra subnets"

##############################################################################
# パラメータ
##############################################################################
Parameters:
  Env:
    Description: Enter the environment. (prd/dev/stg)
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - prd
      - stg

##############################################################################
# リソース
##############################################################################
Resources:
  VPC:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: vpc.yaml
      Parameters:
        Env: !Ref Env
  PublicSubnets:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: public-subnets.yaml
      Parameters:
        Env: !Ref Env
        VpcId: !GetAtt VPC.Outputs.VpcId
  IntraSubnets:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: intra-subnets.yaml
      Parameters:
        Env: !Ref Env
        VpcId: !GetAtt VPC.Outputs.VpcId

##############################################################################
# Outputs
##############################################################################
Outputs:
  DefaultSecurityGroupId:
    Value: !GetAtt VPC.Outputs.DefaultSecurityGroupId
```

vpc.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "VPCのみ"
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
```

public-subnets.yaml

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
  VpcId:
    Description: VPC ID
    Type: String
    AllowedPattern: "vpc-([a-zA-Z0-9])+"

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
      VpcId: !Ref VpcId
  VPCSubnetPubC:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1c
      CidrBlock: 10.0.16.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-pub-subnet-c", !Ref Env ] ]
      VpcId: !Ref VpcId
  VPCSubnetPubD:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1d
      CidrBlock: 10.0.32.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-pub-subnet-d", !Ref Env ] ]
      VpcId: !Ref VpcId
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
      VpcId: !Ref VpcId
  ##############################################################################
  # Route Table(For Public)
  ##############################################################################
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VpcId
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

intra-subnets.yaml

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
  VpcId:
    Description: VPC ID
    Type: String
    AllowedPattern: "vpc-([a-zA-Z0-9])+"

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
      VpcId: !Ref VpcId
  VPCSubnetIntraC:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1c
      CidrBlock: 10.0.64.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-intra-subnet-c", !Ref Env ] ]
      VpcId: !Ref VpcId
  VPCSubnetIntraD:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1d
      CidrBlock: 10.0.80.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-intra-subnet-d", !Ref Env ] ]
      VpcId: !Ref VpcId
  ##############################################################################
  # Route table(For Intra)
  ##############################################################################
  IntraRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VpcId
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
