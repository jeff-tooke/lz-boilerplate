import boto3
import json
import logging
import os
import time

from botocore.exceptions import ClientError

LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=LOG_LEVEL)
logger = logging.getLogger(__name__)

MAX_RETRIES = 5
INITIAL_DELAY = 2  # seconds

ct = boto3.client("controltower")
org = boto3.client("organizations")


def get_org_root_id() -> str:
    """Get the organization root ID."""
    roots = org.list_roots()["Roots"]
    return roots[0]["Id"]


def wait_for_ou_placement(account_id: str, max_retries: int = MAX_RETRIES) -> str:
    """Wait for account to be moved out of org root into target OU.

    Returns the OU ID once the account is placed, or raises RuntimeError
    if the account remains in the root after max retries.
    """
    root_id = get_org_root_id()
    delay = INITIAL_DELAY

    for attempt in range(max_retries):
        parents = org.list_parents(ChildId=account_id)["Parents"]
        parent_id = parents[0]["Id"]

        if parent_id != root_id:
            logger.info(f"Account {account_id} is in OU {parent_id}")
            return parent_id

        logger.info(
            f"Account {account_id} still in root, waiting {delay}s "
            f"(attempt {attempt + 1}/{max_retries})"
        )
        time.sleep(delay)
        delay = min(delay * 2, 30)  # Cap at 30 seconds

    raise RuntimeError(f"Account {account_id} still in root after {max_retries} retries")


def is_control_tower_managed(account_id: str) -> bool:
    try:
        tags = org.list_tags_for_resource(ResourceId=account_id).get("Tags", [])
        tag_map = {t["Key"]: t["Value"] for t in tags}
        return tag_map.get("aws-controltower:managed") == "true"
    except Exception as e:
        logger.warning(f"Could not read tags for {account_id}: {e}")
        return False


def is_already_enrolled(account_id: str) -> bool:
    paginator = ct.get_paginator("list_accounts")
    for page in paginator.paginate():
        for acct in page.get("Accounts", []):
            if acct["AccountId"] == account_id:
                return True
    return False


def enroll_account_in_control_tower(account_id: str, ou_id: str) -> dict:
    """Enroll account in Control Tower with error handling."""
    try:
        ct.enroll_account(AccountId=account_id, ManagedOrganizationalUnitId=ou_id)
        logger.info(f"Enrollment request submitted for {account_id}")
        return {"status": "submitted", "account_id": account_id, "ou_id": ou_id}
    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        if error_code == "ConflictException":
            logger.warning(f"Enrollment already in progress for {account_id}")
            return {"status": "in_progress", "account_id": account_id}
        else:
            logger.error(f"Enrollment failed for {account_id}: {error_code} - {e}")
            raise
    except Exception as e:
        logger.error(f"Unexpected error enrolling {account_id}: {e}")
        raise


def lambda_handler(event, context):
    logger.info(json.dumps(event))

    try:
        account_id = event["detail"]["responseElements"]["createAccountStatus"][
            "accountId"
        ]
    except KeyError:
        logger.info("CreateAccount event but accountId not ready yet")
        return {"status": "skipped", "reason": "account_id_not_ready"}

    logger.info(f"Detected account creation: {account_id}")

    if is_control_tower_managed(account_id):
        logger.info(f"{account_id} is Control Tower vended — skipping")
        return {"status": "skipped", "reason": "control_tower_vended", "account_id": account_id}

    if is_already_enrolled(account_id):
        logger.info(f"{account_id} already enrolled — skipping")
        return {"status": "skipped", "reason": "already_enrolled", "account_id": account_id}

    # Wait for account to be moved from org root to target OU
    # (Terraform creates the account and moves it, but these are separate operations)
    try:
        ou_id = wait_for_ou_placement(account_id)
    except RuntimeError as e:
        logger.error(str(e))
        raise

    logger.info(f"Enrolling account {account_id} into OU {ou_id}")
    return enroll_account_in_control_tower(account_id, ou_id)
