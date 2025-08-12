# スプリント3：AWS環境構築（Terraform）

このリポジトリは、スプリント1で作成したTerraformコード（`main.tf`）をまとめたものです。AWS上にWebサーバ／APIサーバ（2台）／RDS(MySQL) を構築し、API はインターネット向け ALB 配下で負荷分散されます。

---

## 構成概要

- **VPC**: 10.0.0.0/21
- **サブネット**
  - 公開: Web 用 (10.0.0.0/24)、API 用 ×2 (10.0.1.0/24, 10.0.4.0/24)、ALB 用 ×2 (10.0.5.0/24, 10.0.6.0/24)
  - 非公開: DB 用 ×2 (10.0.2.0/24, 10.0.3.0/24)
  - すべて IGW へ向く **Public ルートテーブル**を Web/API/ALB に関連付け（DB は関連付け無し=デフォルト RT）
- **EC2**
  - Web: Amazon Linux、1台（公開サブネット）
  - API: Amazon Linux、2台（別AZ：`ap-northeast-1a` / `1c` の公開サブネット）
- **ALB**: インターネット向け、HTTP(80) リスナー、ターゲットグループは API 2台を登録（ヘルスチェック `/`）
- **RDS (MySQL 8.0)**: マルチAZにまたがる DB サブネットグループに配置、**Publicly Accessible = false**、**暗号化有効**

---

## 使用技術

- Terraform
- AWS: VPC / EC2 / ALB(Application Load Balancer) / RDS(MySQL) / IGW / SG
- （任意）Tera Term or OpenSSH（サーバ設定用のSSHクライアント）

---

## セキュリティ方針（SG ルール要約）

- **ALB SG**: TCP/80 を全世界から許可（学習用。本番は WAF や CIDR 制限・HTTPS を推奨）
- **API SG**: TCP/80 は **ALB SG からのみ**、SSH(22) は `var.myip` のみ
- **Web SG**: TCP/80, 22 を全世界から（学習用）
- **DB SG**: TCP/3306 は **API SG からのみ**、RDS は **Publicly Accessible: false**

> 重要: `var.myip` のデフォルトは `0.0.0.0/0`（全開放）です。必ず自分のIP/32 に変更してください。

---

## 事前準備

- AWS 認証情報（環境変数 or プロファイル）
- 既存のキーペア名（`var.key_name`）を正しく設定
- 必要に応じて AMI ID を利用リージョンの最新 Amazon Linux へ更新

---

## 使い方

```bash
# 初回
terraform init

# 変数を適宜上書き
terraform plan \
  -var "myip=xxx.xxx.xxx.xxx/32" \
  -var "key_name=your-key-pair"

# 反映
terraform apply \
  -var "myip=xxx.xxx.xxx.xxx/32" \
  -var "key_name=your-key-pair"
```

### 出力確認（Outputs）

```bash
terraform output alb_dns_name
terraform output rds_endpoint
terraform output rds_master_secret_arn
```

- `alb_dns_name` … ブラウザや `curl` でアクセス（アプリ未導入時は 5xx/Unhealthy）
- `rds_endpoint` … アプリの DB 接続先
- `rds_master_secret_arn` … Secrets Manager 上の管理ユーザパスワードのシークレット ARN

---

## ディレクトリ構成（例）

```
.
├─ main.tf              # 本リポジトリの Terraform コード
└─ README.md            # このドキュメント
```

> 将来的には `vpc.tf` / `alb.tf` / `ec2.tf` / `rds.tf` / `variables.tf` / `outputs.tf` などに分割することを推奨します。

---

## よくある変更ポイント

- **プライベート化**: API をプライベートサブネットへ移し、NAT Gateway + プライベート RT を導入
- **HTTPS 化**: ACM 証明書を発行し、ALB の 443 リスナー＋リダイレクトを設定
- **ユーザーデータ/構成管理**: アプリの自動デプロイ・設定管理（SSM/Ansible/Cloud-Init）
- **可用性・スケーリング**: Auto Scaling Group / Launch Template で API を水平スケール
- **運用強化**: CloudWatch アラーム / ログ集約 / RDS バックアップ保持期間の調整

---

## 片付け（Destroy）

```bash
terraform destroy \
  -var "myip=xxx.xxx.xxx.xxx/32" \
  -var "key_name=your-key-pair"
```

> 事前に EC2 上で保持しているログやデータを退避してください。RDS は `skip_final_snapshot = true` のためスナップショットは残りません（本番は `true`→`false` を検討）。

