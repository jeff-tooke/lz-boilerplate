# Terraform State Module

A resilient Terraform state backend module with cross-region replication for disaster recovery. This module creates S3 buckets for state storage, DynamoDB Global Tables for state locking, and KMS keys for encryption - all replicated to a DR region.

## Features

- **S3 State Storage** with versioning, encryption, and access logging
- **Cross-Region Replication** (CRR) with 15-minute SLA
- **DynamoDB Global Tables** for lock failover (no manual intervention needed)
- **Multi-Region KMS Keys** for encryption in both regions
- **Security Hardening**: TLS enforcement, public access blocks, encryption requirements
- **Lifecycle Management**: Automatic cleanup of old state versions
- **Cross-Account Support**: Optional access for multiple AWS accounts

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Resilient Terraform State Backend                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Primary Region (eu-west-1)              DR Region (eu-west-2)            │
│   ┌─────────────────────────┐             ┌─────────────────────────┐      │
│   │  S3: terraform-state    │────CRR─────▶│  S3: terraform-state-dr │      │
│   │  - Versioning enabled   │  (15 min)   │  - Versioning enabled   │      │
│   │  - KMS encryption       │             │  - KMS encryption       │      │
│   │  - Access logging       │             │                         │      │
│   └─────────────────────────┘             └─────────────────────────┘      │
│                                                                             │
│   ┌─────────────────────────┐             ┌─────────────────────────┐      │
│   │  KMS: Multi-Region Key  │────────────▶│  KMS: Replica Key       │      │
│   │  (Primary)              │             │  (Auto-synced)          │      │
│   └─────────────────────────┘             └─────────────────────────┘      │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐      │
│   │              DynamoDB Global Table: terraform-locks             │      │
│   │         (Active-Active replication, automatic failover)         │      │
│   └─────────────────────────────────────────────────────────────────┘      │
│                                                                             │
│   ┌─────────────────────────┐                                              │
│   │  S3: terraform-logs     │  (Access logging for audit)                  │
│   └─────────────────────────┘                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Setup with DR

```hcl
module "terraform_state" {
  source = "./terraform-state"

  name           = "mycompany"
  environment    = "shared"
  primary_region = "eu-west-1"

  # Enable cross-region replication
  dr_enabled = true
  dr_region  = "eu-west-2"

  tags = {
    Project = "platform"
  }
}
```

### Using the Backend

After applying the module, configure your Terraform projects:

```hcl
# In your project's backend.tf
terraform {
  backend "s3" {
    # Values from module outputs
    bucket         = "mycompany-terraform-state"
    region         = "eu-west-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-1:123456789:key/xxx"
    dynamodb_table = "mycompany-terraform-locks"
    key            = "path/to/your/state.tfstate"
  }
}
```

Or use partial configuration with backend config files:

```hcl
terraform {
  backend "s3" {}
}
```

```bash
# Initialize with primary backend
terraform init -backend-config=backend-primary.hcl

# Or with DR backend during failover
terraform init -backend-config=backend-dr.hcl -reconfigure
```

### Backend Config File Format

The module outputs ready-to-use HCL configurations:

```hcl
# backend-primary.hcl
bucket         = "mycompany-terraform-state"
region         = "eu-west-1"
encrypt        = true
kms_key_id     = "arn:aws:kms:eu-west-1:123456789:key/xxx"
dynamodb_table = "mycompany-terraform-locks"

# backend-dr.hcl
bucket         = "mycompany-terraform-state-dr"
region         = "eu-west-2"
encrypt        = true
kms_key_id     = "arn:aws:kms:eu-west-2:123456789:key/yyy"
dynamodb_table = "mycompany-terraform-locks"  # Same global table!
```

## Failover Procedure

### Automatic (DynamoDB Locks)

DynamoDB Global Tables handle lock failover automatically. If the primary region is down, lock operations continue to work against the DR region replica.

### Manual (S3 State)

During a primary region outage:

```bash
# 1. Your normal init will fail/timeout
terraform init -backend-config=backend-primary.hcl
# Error: timeout connecting to S3

# 2. Reconfigure to use DR backend
terraform init -backend-config=backend-dr.hcl -reconfigure

# 3. Verify state is recent (check replication lag)
terraform state list

# 4. Continue operations
terraform plan
terraform apply
```

### Pipeline Integration

```bash
#!/bin/bash
# Failover-aware initialization script

PRIMARY_BACKEND="backend-primary.hcl"
DR_BACKEND="backend-dr.hcl"
TIMEOUT=30

echo "Attempting primary backend..."
if timeout $TIMEOUT terraform init -backend-config=$PRIMARY_BACKEND 2>/dev/null; then
    echo "Connected to primary backend"
else
    echo "Primary failed, switching to DR backend..."
    terraform init -backend-config=$DR_BACKEND -reconfigure
    echo "WARNING: Using DR backend - verify state freshness!"
fi
```

## Inputs

### General

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for resources | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| primary_region | Primary AWS region | `string` | n/a | yes |
| tags | Additional tags | `map(string)` | `{}` | no |

### DR Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dr_enabled | Enable cross-region replication | `bool` | `true` | no |
| dr_region | DR region | `string` | `""` | when dr_enabled |

### S3 Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_suffix | Optional bucket name suffix | `string` | `""` | no |
| force_destroy | Allow destroying non-empty buckets | `bool` | `false` | no |
| versioning_enabled | Enable versioning | `bool` | `true` | no |
| mfa_delete_enabled | Require MFA for deletions | `bool` | `false` | no |
| lifecycle_rules | Lifecycle configuration | `object` | see below | no |

Default lifecycle rules:
```hcl
{
  enabled                       = true
  noncurrent_version_expiration = 90
  abort_incomplete_upload_days  = 7
}
```

### DynamoDB Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dynamodb_table_name | Custom table name | `string` | `""` | no |
| dynamodb_billing_mode | PAY_PER_REQUEST or PROVISIONED | `string` | `"PAY_PER_REQUEST"` | no |
| dynamodb_point_in_time_recovery | Enable PITR | `bool` | `true` | no |

### Encryption

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| kms_key_deletion_window | Days before key deletion (7-30) | `number` | `30` | no |
| kms_enable_key_rotation | Enable automatic rotation | `bool` | `true` | no |

### Access Control

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allowed_account_ids | AWS accounts for cross-account access | `list(string)` | `[]` | no |
| denied_ip_ranges | IP ranges to explicitly deny | `list(string)` | `[]` | no |

### Logging

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access_logging_enabled | Enable S3 access logging | `bool` | `true` | no |
| access_logging_bucket | Existing log bucket (creates new if empty) | `string` | `""` | no |
| access_logging_prefix | Log object prefix | `string` | `"terraform-state-logs/"` | no |

## Outputs

### Primary Region

| Name | Description |
|------|-------------|
| state_bucket_id | Primary state bucket ID |
| state_bucket_arn | Primary state bucket ARN |
| state_bucket_region | Primary region |
| kms_key_id | Primary KMS key ID |
| kms_key_arn | Primary KMS key ARN |
| dynamodb_table_name | Lock table name (global) |
| dynamodb_table_arn | Lock table ARN |

### DR Region

| Name | Description |
|------|-------------|
| dr_state_bucket_id | DR state bucket ID |
| dr_state_bucket_arn | DR state bucket ARN |
| dr_state_bucket_region | DR region |
| dr_kms_key_id | DR KMS key ID |
| dr_kms_key_arn | DR KMS key ARN |
| replication_role_arn | Replication IAM role ARN |

### Backend Configurations

| Name | Description |
|------|-------------|
| backend_config_primary | Primary backend config (map) |
| backend_config_dr | DR backend config (map) |
| backend_hcl_primary | Primary backend config (HCL string) |
| backend_hcl_dr | DR backend config (HCL string) |

## Security Features

- **TLS Enforcement**: Denies non-HTTPS requests
- **Encryption Enforcement**: Denies unencrypted uploads
- **KMS Key Enforcement**: Denies uploads with wrong KMS key
- **Public Access Block**: All public access blocked
- **Versioning**: Protects against accidental deletion
- **Access Logging**: Audit trail for compliance

## Important Considerations

### Replication Lag

S3 Cross-Region Replication has a 15-minute SLA. During failover:
- State may be up to 15 minutes behind
- Always verify state freshness before making changes
- Consider the implications of reverting recent changes

### Cost

DR-enabled deployment includes:
- 2x S3 buckets (storage and request costs)
- 2x KMS keys (key usage costs)
- DynamoDB Global Table (replication costs)
- S3 replication (data transfer costs)

### Bootstrapping

This module cannot use the backend it creates. Initial deployment requires:
1. Apply with local state
2. Migrate to remote backend after creation

```bash
# First apply - creates infrastructure
terraform apply

# Then migrate state to the new backend
terraform init -backend-config=backend-primary.hcl -migrate-state
```

## Version Requirements

| Requirement | Version |
|-------------|---------|
| Terraform | >= 1.5.0, < 2.0.0 |
| AWS Provider | >= 5.0, < 6.0 |
| Module Version | 1.0.0 |
