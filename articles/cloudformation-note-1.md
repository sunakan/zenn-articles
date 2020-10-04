---
title: CFnでVPCを作ったり消したりする～基本～
emoji: 📝
type: tech
topics: [CloudFormation]
published: true
---

### CFnって何？とかなら以下の教材の無料の範囲のサンプル部分がわかりやすかった（確認したときはSection3まで無料）

- [AWS CloudFormation を使って VPC環境を構築してみよう！](https://www.techpit.jp/courses/77)

## 基本これ！「Resourcesセクション」

```yaml
Resources:
  論理ID:
    Type: リソースタイプ
    Properties:
      リソースプロパティ
```

| プロパティ | 説明 |
| -------- | -------- |
|論理ID|英数字（A-Za-z0-9）を利用。テンプレート内で一意である必要がある。|
|リソースタイプ|作成するAWSリソースを宣言。|
|リソースプロパティ|リソース毎に決めるプロパティ（必須もあればオプショナルもある）|

[リソースタイプ一覧（公式）](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)

## 作成と更新と削除

作成

```bash
$ aws cloudformation create-stack --stack-name スタック名 --template-body file://./main.yaml
```

更新

```bash
$ aws cloudformation update-stack --stack-name スタック名 --template-body file://./main.yaml
```

削除

```bash
$ aws cloudformation delete-stack --stack-name スタック名
```

## 構成図の見方

AWSのClodFormationのスタックを選択して右上のテンプレートからデザイナーをクリックから見える

![](https://i.imgur.com/VevPRVE.png)

## たった１つのVPC

![](https://i.imgur.com/AksLlzZ.png)


main.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Resources:
  FirstVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
```

## サブネット２つ

![](https://i.imgur.com/mywCYeZ.png)

main.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: test-vpc
  VPCSubnetA:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1a
      CidrBlock: 10.0.0.0/20
      Tags:
      - Key: Name
        Value: test-pub-subnet-a
      VpcId: !Ref VPC
  VPCSubnetC:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1c
      CidrBlock: 10.0.16.0/20
      Tags:
        - Key: Name
          Value: test-pub-subnet-c
      VpcId: !Ref VPC
```

## パブリックサブネット３つ、イントラサブネット３つ

NATゲートウェイを置きたくなかったのでイントラネットとした

![](https://i.imgur.com/VcefWgL.png)

main.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Resources:
  ##############################################################################
  # VPC
  ##############################################################################
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: test-vpc
  ##############################################################################
  # VPC Subnet(Pulic)
  ##############################################################################
  VPCSubnetPubA:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1a
      CidrBlock: 10.0.0.0/20
      Tags:
      - Key: Name
        Value: test-pub-subnet-a
      VpcId: !Ref VPC
  VPCSubnetPubC:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1c
      CidrBlock: 10.0.16.0/20
      Tags:
        - Key: Name
          Value: test-pub-subnet-c
      VpcId: !Ref VPC
  VPCSubnetPubD:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1d
      CidrBlock: 10.0.32.0/20
      Tags:
        - Key: Name
          Value: test-pub-subnet-d
      VpcId: !Ref VPC
  ##############################################################################
  # Internet Gateway
  ##############################################################################
  IGW:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
      - Key: Name
        Value: test-igw
  AttachIGW:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId: !Ref IGW
      VpcId: !Ref VPC
  ##############################################################################
  # Route Table(For Public)
  ##############################################################################
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
      - Key: Name
        Value: test-rt
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
        Value: test-intra-subnet-a
      VpcId: !Ref VPC
  VPCSubnetIntraC:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1c
      CidrBlock: 10.0.64.0/20
      Tags:
        - Key: Name
          Value: test-intra-subnet-c
      VpcId: !Ref VPC
  VPCSubnetIntraD:
    Type: AWS::EC2::Subnet
    Properties:
      AvailabilityZone: ap-northeast-1d
      CidrBlock: 10.0.80.0/20
      Tags:
        - Key: Name
          Value: test-intra-subnet-d
      VpcId: !Ref VPC
  ##############################################################################
  # Route table(For Intra)
  ##############################################################################
  IntraRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
      - Key: Name
        Value: test-intra-rt
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
