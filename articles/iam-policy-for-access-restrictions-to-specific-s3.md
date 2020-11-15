---
title: 特定のS3の特定のディレクトリ以下だけ読み書き可能なIAMポリシー
emoji: 📝
type: tech
topics: [IAM]
published: true
---

## ざっくり要件

- 不要なAWSリソースを見たくない・見せたくないIAMユーザを作成したい
- 特定のS3のapp/以下だけ（重要）
- アクションとしては、ディレクトリ作成、アップロード、ダウンロード、閲覧
- 他のS3バケット名も見せない
- IP制限等は別途
- MFA付き等は今回は除外
- バケット名は参考から名前を流用して `AWSDOC-EXAMPLE-BUCKET`
- S3バケットは東京リージョン

## 個人的なポイント

- バケットポリシー側をいじる必要はなかった
- S3バケットのアクセス許可も `パブリックアクセスをすべてブロック` のままでよい
- 特定のURLでアクセスする必要がある
  - https://s3.console.aws.amazon.com/s3/buckets/AWSDOC-EXAMPLE-BUCKET?region=ap-northeast-1&prefix=app/
  - S3のバケット一覧からは遷移できない(権限がないため。一部だけ閲覧できるやり方を見つけられなかった)

## IAMポリシー

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucketVersions",
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::AWSDOC-EXAMPLE-BUCKET",
            "Condition": {
                "StringLike": {
                    "s3:prefix": "app/*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "s3:GetBucketVersioning",
            "Resource": "arn:aws:s3:::AWSDOC-EXAMPLE-BUCKET"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObjectAcl",
                "s3:GetObject",
                "s3:DeleteObjectVersion",
                "s3:GetObjectVersionTagging",
                "s3:GetObjectVersionAcl",
                "s3:GetObjectTagging",
                "s3:DeleteObject",
                "s3:GetObjectVersion"
            ],
            "Resource": "arn:aws:s3:::AWSDOC-EXAMPLE-BUCKET/app/*"
        }
    ]
}
```

### 参考

[特定のバケットに対する Amazon S3 コンソールのアクセス許可をユーザーに付与するにはどうすればよいですか?](https://aws.amazon.com/jp/premiumsupport/knowledge-center/s3-console-access-certain-bucket/)
