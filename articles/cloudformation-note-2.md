---
title: CFnでVPCを作ったり消したりする～パラメータの利用～
emoji: 📝
type: tech
topics: [CloudFormation]
published: true
---

## パラメータ

公式ドキュメントの「パラメータの一般要件」がわかりやすい

[CloudFormation > ユーザーガイド > パラメータ#パラメータの一般要件](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#parameters-section-structure-requirements)

```yaml
Parameters:
  パラメータの論理ID:
    Type: パラメータのデータ型
    パラメータのプロパティ: value
```

[パラメータのプロパティ一覧](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#parameters-section-structure-properties)

プロパティの例（IPv4の簡単な例、256以上も通ってはしまう）

```yaml
MyCidr:
    Description: IPv4 CIDR Block (0.0.0.0/0)
    Type: String
    MinLength: 9
    MaxLength: 18
    AllowedPattern: "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\/(\\d{1,2})"
    ConstraintDescription: Please specify the IPv4 Network Address and Subnet Mask.
```

## 作成と更新と削除

作成

```bash
$ aws cloudformation create-stack --stack-name スタック名 --template-body file://./main.yaml --parameters --parameters ParameterKey=Env,ParameterValue=dev
```

更新

```bash
$ aws cloudformation update-stack --stack-name スタック名 --template-body file://./main.yaml --parameters --parameters ParameterKey=Env,ParameterValue=dev
```

削除

```bash
$ aws cloudformation delete-stack --stack-name スタック名
```

## VPC１つだけ

main.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "３つのパブリックサブネットと３つのイントラネット"

##############################################################################
# パラメータ
##############################################################################
Parameters:
  Env:
    Type: String
    Default: staging
    AllowedValues:
     - dev
     - prd
     - stg
    Description: Enter the environment. (prd/dev/stg)

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
          Value: !Join [ "-", [ "test-vpc", !Ref Env ] ]
```


## 注意：Envだけを変更すると、更新という形で上書く

解決法：スタック名も変更する
