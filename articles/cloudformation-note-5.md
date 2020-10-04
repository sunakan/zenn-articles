---
title: CFnでVPCを作ったり消したりする～ファイル分割パターン３～
emoji: 📝
type: tech
topics: [CloudFormation]
published: true
---

- パラメータストアを利用してVPCIDを渡す

例

```yaml
  SSMVpcId:
    Type: AWS::SSM::Parameter
    Properties:
      Type: String
      Name: !Join [ "/", [ "/cfn/global/vpc", !Ref Env, "vpc-id" ] ]
      Value: !Ref VPC
```

SecureStringの作成はサポートしてないらしい（いつかきっとサポートされるはず！参照は可能っぽい）

[CloudFormation > ユーザーガイド > AWS::SSM::Parameter](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-resource-ssm-parameter.html)
のTypeの部分にて

> AWS CloudFormation は SecureString パラメータタイプの作成をサポートしていません。

パラメータストアに/cfn/global/vpc/dev/vpc-idにVPC IDを保存して、それを他で流用する

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
  SSMVpcId:
    Type: AWS::SSM::Parameter
    Properties:
      Type: String
      Name: !Join [ "/", [ "/cfn/global/vpc", !Ref Env, "vpc-id" ] ]
      Value: !Ref VPC

##############################################################################
# Output
##############################################################################
Outputs:
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
      VpcId: !Sub "{{resolve:ssm:/cfn/global/vpc/${Env}/vpc-id:1}}"
  VPCSubnetPubC:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1c
      CidrBlock: 10.0.16.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-pub-subnet-c", !Ref Env ] ]
      VpcId: !Sub "{{resolve:ssm:/cfn/global/vpc/${Env}/vpc-id:1}}"
  VPCSubnetPubD:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1d
      CidrBlock: 10.0.32.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-pub-subnet-d", !Ref Env ] ]
      VpcId: !Sub "{{resolve:ssm:/cfn/global/vpc/${Env}/vpc-id:1}}"
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
      VpcId: !Sub "{{resolve:ssm:/cfn/global/vpc/${Env}/vpc-id:1}}"
  ##############################################################################
  # Route Table(For Public)
  ##############################################################################
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Sub "{{resolve:ssm:/cfn/global/vpc/${Env}/vpc-id:1}}"
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
      VpcId: !Sub "{{resolve:ssm:/cfn/global/vpc/${Env}/vpc-id:1}}"
  VPCSubnetIntraC:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1c
      CidrBlock: 10.0.64.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-intra-subnet-c", !Ref Env ] ]
      VpcId: !Sub "{{resolve:ssm:/cfn/global/vpc/${Env}/vpc-id:1}}"
  VPCSubnetIntraD:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1d
      CidrBlock: 10.0.80.0/20
      Tags:
        - Key: Name
          Value: !Join [ "-", [ "test-intra-subnet-d", !Ref Env ] ]
      VpcId: !Sub "{{resolve:ssm:/cfn/global/vpc/${Env}/vpc-id:1}}"
  ##############################################################################
  # Route table(For Intra)
  ##############################################################################
  IntraRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Sub "{{resolve:ssm:/cfn/global/vpc/${Env}/vpc-id:1}}"
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

### 参考

- [[Tips]CloudFormationで文字列の繰り返しやめたいと思ったのでAWS Systems Manager パラメータストアに保存することを思いついた話](https://dev.classmethod.jp/articles/cloudformation-ssmparam/)
- [[小ネタ] CloudFormationの組み込み関数を使った文字列操作の備忘録](https://dev.classmethod.jp/articles/cloud%E2%80%8Bformation-intrinsic-function-memorandum/)
- [[新機能]AWS CloudFormationでAWS Systems ManagerパラメータストアのSecureStringがサポートされました](https://dev.classmethod.jp/articles/aws-cloudformation-support-dynamic-references-securestring/)
