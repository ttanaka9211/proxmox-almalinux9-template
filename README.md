# Proxmox AlmaLinux 9 Template Builder

このプロジェクトは、ProxmoxでAlmaLinux 9のテンプレートを自動作成するためのPacker/Terraform設定です。

## 構成

- `packer/` - AlmaLinux 9テンプレートをビルドするPacker設定
- `terraform/` - Proxmoxリソースを管理するTerraform設定

## 使用方法

### 1. 事前準備

1. Proxmox APIトークンを作成
2. AlmaLinux 9のISOをProxmoxにアップロード

### 2. 設定ファイルの準備

```bash
# Packer用
cp packer/secrets.auto.pkrvars.hcl.example packer/secrets.auto.pkrvars.hcl
# 編集して実際の値を設定

# Terraform用
cp terraform/secrets.auto.tfvars.example terraform/secrets.auto.tfvars
# 編集して実際の値を設定
```

### 3. テンプレートのビルド

```bash
cd packer
packer build .
```

## 既知の問題

- AlmaLinux 9のUEFIブートでkickstart自動インストールが正しく動作しない場合がある
- 解決策: kickstartファイルをGitHub等の外部URLに配置する
