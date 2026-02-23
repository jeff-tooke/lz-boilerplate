"""
AFT Global Customisations — Pre-API Helper

Copies the federation role ARN for the vended account's OU from the AFT
management account into the newly vended account so that the global
customisations Terraform can read it locally without cross-account calls.

The OU name is read from /aft/account-request/custom-fields/ou_name, which
AFT writes from the account request custom_fields block. The final path
segment (slug) is used to look up the per-OU parameter in the AFT management
account, e.g. "Root/infrastructure/it-nonprod" → slug "it-nonprod" →
/aft/config/ou-federation-role/it-nonprod.

The resolved ARN is written to /aft/config/federation-role-arns in the
vended account — the same destination path consumed by the global
customisations Terraform, so no downstream changes are required.

Pre-requisite: Create /aft/config/ou-federation-role/<slug> as a String in
the AFT management account (eu-west-2) for every OU slug before running AFT.

Example per-OU parameters in the AFT management account:
  /aft/config/ou-federation-role/it-nonprod  → arn:aws:iam::MGMT:role/ado-federation-it-nonprod
  /aft/config/ou-federation-role/it-prod     → arn:aws:iam::MGMT:role/ado-federation-it-prod
  /aft/config/ou-federation-role/sandbox     → arn:aws:iam::MGMT:role/ado-federation-sandbox
"""

import boto3

OU_NAME_PARAM = "/aft/account-request/custom-fields/ou_name"
OU_FEDERATION_ROLE_PREFIX = "/aft/config/ou-federation-role"
DEST_PARAM = "/aft/config/federation-role-arns"


def get_aft_management_account_id() -> str:
    """Reads the AFT management account ID from the known AFT SSM parameter."""
    ssm = boto3.client("ssm")
    response = ssm.get_parameter(Name="/aft/account/aft-management/account-id")
    return response["Parameter"]["Value"]


def get_ou_name_from_vended_account() -> str:
    """Reads the OU name written by AFT from the vended account's custom fields."""
    ssm = boto3.client("ssm")
    response = ssm.get_parameter(Name=OU_NAME_PARAM)
    return response["Parameter"]["Value"]


def derive_ou_slug(ou_name: str) -> str:
    """
    Derives the OU slug from the full OU path by taking the final segment.

    Examples:
      "Root/infrastructure/it-prod"  → "it-prod"
      "Root/core"                    → "core"
      "Root/sandbox"                 → "sandbox"
    """
    return ou_name.rstrip("/").split("/")[-1]


def get_federation_role_arn(mgmt_account_id: str, ou_slug: str) -> str:
    """
    Reads the federation role ARN for the given OU slug from the AFT management
    account SSM. Raises ValueError if no parameter exists for the slug.
    """
    sts = boto3.client("sts")
    assumed = sts.assume_role(
        RoleArn=f"arn:aws:iam::{mgmt_account_id}:role/AWSAFTExecution",
        RoleSessionName="aft-pre-hook-federation-role",
    )
    creds = assumed["Credentials"]

    mgmt_ssm = boto3.client(
        "ssm",
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
    )

    param_name = f"{OU_FEDERATION_ROLE_PREFIX}/{ou_slug}"
    try:
        response = mgmt_ssm.get_parameter(Name=param_name)
    except mgmt_ssm.exceptions.ParameterNotFound:
        raise ValueError(
            f"No federation role parameter found for OU slug '{ou_slug}'. "
            f"Expected SSM parameter '{param_name}' in AFT management account "
            f"{mgmt_account_id}. Create this parameter before vending accounts "
            f"into this OU."
        )
    return response["Parameter"]["Value"]


def write_to_vended_account(value: str) -> None:
    """Writes the federation role ARN into the vended account SSM."""
    ssm = boto3.client("ssm")
    ssm.put_parameter(
        Name=DEST_PARAM,
        Description="Federation role ARN allowed to assume the Terraform execution role",
        Value=value,
        Type="String",
        Overwrite=True,
        Tier="Standard",
    )
    print(f"Written {DEST_PARAM} to vended account SSM")


def main():
    ou_name = get_ou_name_from_vended_account()
    ou_slug = derive_ou_slug(ou_name)
    print(f"OU name: {ou_name!r} → slug: {ou_slug!r}")

    mgmt_account_id = get_aft_management_account_id()
    federation_role_arn = get_federation_role_arn(mgmt_account_id, ou_slug)
    write_to_vended_account(federation_role_arn)


if __name__ == "__main__":
    main()
