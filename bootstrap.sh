#!/bin/bash

PARAMS=""
TMP_DIR=""
PROJECT_ARG="caylent-gitops"

# Validate that terraform is installed
validate_terraform () {
  echo "Validating terraform is installed..."
  if terraform -v; then
    echo "  terraform is INSTALLED."
  else
    echo "  terraform is NOT INSTALLED."
    echo "  Please install the terraform command line tools first..."
    echo "  These can be found at https://www.terraform.io/downloads.html"
    return 1
  fi
}

# Validate that gsutil is installed
validate_gsutil () {
  echo "Validating gsutil is installed..."
  if gsutil -v; then
    echo "  gsutil is INSTALLED."
  else
    echo "  gsutil is NOT INSTALLED."
    echo "  Please install the Google Cloud SDK first..."
    echo "  See https://cloud.google.com/sdk/docs/quickstart for downloads and instructions"
    return 1
  fi
}

# Validate that the git is installed
validate_git () {
  echo "Validating git is installed..."
  if git --version; then
    echo "  git is INSTALLED."
  else
    echo "  git is NOT INSTALLED."
    echo "  Please install the git command line tools first..."
    return 1
  fi
}

# Validate that the GitHub CLI is installed
validate_github () {
  echo "Validating GitHub CLI is installed..."
  if gh --version; then
    echo "  GitHub CLI is INSTALLED."
  else
    echo "  GitHub CLI is NOT INSTALLED."
    echo "  Please install the GitHub command line tools first..."
    return 1
  fi
}

# Update terraform backend bucket
update_tfbackend_bucket () {
  echo "Updating terraform backend bucket to $1 ..."
  find . -type f -name "backend.tf" -exec \
    sed -i '' -e "s/bucket[[:space:]]*=[[:space:]]*\"[_a-zA-Z0-9-]*\"/bucket = \"$1\"/g" {} +
}

# Update tfvars files with key / value pair
update_tfvars () {
  echo "Updating tfvars for key=$1 to value=$2 ..."
  find . -type f -name "*.tfvars" -exec \
    sed -i '' -e "s/$1[[:space:]]*=[[:space:]]*\"[_a-zA-Z0-9-]*\"/$1 = \"$2\"/g" {} +
}

# Update the name of the state bucket
update_state_bucket () {
  update_tfvars tf_state_bucket "$1"
}

# Update github repository owner
update_github_owner () {
  update_tfvars github_owner "$1"
}

# Update config repository name
update_config_repo () {
  echo "Updating cloudbuild.yaml for _CONFIG_REPO=$1 ..."
  find . -type f -name "cloudbuild.yaml" -exec \
    sed -i '' -e "s/_CONFIG_REPO:[[:space:]]*[_a-zA-Z0-9-]*/_CONFIG_REPO: $2/g" {} +
}

# Update app repository name
update_app_repo () {
  update_tfvars github_app_repo "$1"
}

# Update infra repository name
update_infra_repo () {
  update_tfvars github_infra_repo "$1"
}

# Git add, commit and push with message
git_add_commit_push () {
  git status --porcelain | awk 'match($1, "M"){print $2}' | xargs git add
  git commit -m "$1"
  git push
  echo "Changes added, committed and pushed to git ..."
}

gcp_create_tfstate_bucket () {
  gsutil mb -b on -l US -p caylent-gitops gs://"$1"
  gsutil versioning set on gs://"$1"
}

# Terraform init, plan, apply
terraform_ipa () {
  terraform init
  terraform plan -out="$1"
  terraform apply -auto-approve ./"$1"
  rm "$1"
}

# Generate a random alphanumeric value (lower and upper case) of a length supplied by first argument
random_alphanum () {
  # shellcheck disable=SC2002
  cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w "$1" | head -n 1
}

# Generate a random alphanumeric value (lower case only) of a length supplied by first argument
random_alphanum_lower () {
  # shellcheck disable=SC2002
  cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | fold -w "$1" | head -n 1
}

create_tmp_dir () {
  TMP_DIR=/tmp/caylent-gitops-$(random_alphanum 16)
  echo "Creating temp directory $TMP_DIR ..."
  mkdir -p "$TMP_DIR"
}

cleanup_tmp_dir () {
  echo "Removing temp directory $TMP_DIR ..."
  rm -rf "$TMP_DIR"
}

gen_argocd_ssh_keys () {

  #  Generate keypair in tmp directory
  ssh-keygen -t ed25519 -f "$TMP_DIR"/argocd-github-ssh-key-"$1" -C "ArgoCD Service - $1" -q -N ""

  # Create a Google Cloud Secret Manager entry for the private ssh key
  #   (to be used by argocd for accessing private GitHub repos)
  gcloud secrets create argocd-github-ssh-private-key-"$1" \
    --replication-policy="automatic" --data-file="$TMP_DIR"/argocd-github-ssh-key-"$1"

}

gen_argocd_admin_password () {
  random_alphanum 16 > "$TMP_DIR"/argocd-admin-password-"$1"
  gcloud secrets create argocd-admin-password-"$1" \
    --replication-policy="automatic" --data-file="$TMP_DIR"/argocd-admin-password-"$1"
}

github_add_public_ssh_key () {

  gh ssh-key add "$TMP_DIR"/argocd-github-ssh-key-"$1".pub -t "ArgoCD SSH Key - $1" || {
      # Make sure we have permission to write a public key
      gh auth refresh -s write:public_key && {
        gh ssh-key add "$TMP_DIR"/argocd-github-ssh-key-"$1".pub -t "ArgoCD SSH Key - $1"
      }
  }

}

while (("$#")); do
  case "$1" in
  -c | --cloud)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      CLOUD_ARG=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      exit 1
    fi
    ;;
  -o | --owner)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      GITHUB_ARG=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      exit 1
    fi
    ;;
  -p | --project)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      PROJECT_ARG=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      exit 1
    fi
    ;;
  -a | --app-repo)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      APP_ARG=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      exit 1
    fi
    ;;
  -e | --config-repo)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      CONFIG_ARG=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      exit 1
    fi
    ;;
  -i | --infra-repo)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      INFRA_ARG=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      exit 1
    fi
    ;;
  -* ) # Unsupported flags
    echo "Error: Unsupported flag $1" >&2
    exit 1
    ;;
  *) # Preserve positional arguments
    PARAMS="$PARAMS $1"
    shift
    ;;
  esac
done

case "$CLOUD_ARG" in
aws)
  echo "AWS selected..."
  # NOT IMPLEMENTED YET
  ;;
gcp)
  echo "GCP selected..."
  echo "Validating tools installation..."

  # Please note that the tool checks below use a function invocation pattern
  #   that looks like 'function || { statement; }'.  This notation may look unusual,
  #   but it simply means that the statement block will be executed if the function
  #   call returns a non-zero value.  This is done intentionally rather than hard-coding
  #   exit calls within the functions to provide flexibility in the event that future
  #   use cases may wish to check tool installation without aborting the script execution.
  #   For example, for optional tools installations based on cli flags.

  # Validate that gsutil is installed
  validate_gsutil || { exit $?; }

  # Validate that terraform is installed
  validate_terraform || { exit $?; }

  # Validate that git is installed
  validate_git || { exit $?; }

  # Validate that GitHub CLI is installed
  validate_github || { exit $?; }

  # Generate a random alpha-numeric "run number" so that multiple users in the same account can run this script
  GITOPS_RUN_NUM="$(random_alphanum_lower 6)"

  # Execute this block if the user has indicated any tfvars values need updating
  if [ -n "$GITHUB_ARG" ] || [ -n "$PROJECT_ARG" ] || [ -n "$APP_ARG" ] || [ -n "$CONFIG_ARG" ] [ -n "$INFRA_ARG" ]; then

    # Update state bucket name
    if [ -n "$GITOPS_RUN_NUM" ]; then
      update_tfbackend_bucket "$PROJECT_ARG-tfstate-$GITOPS_RUN_NUM"
      update_state_bucket "$PROJECT_ARG-tfstate-$GITOPS_RUN_NUM"
    fi

    # Update github repository owner
    if [ -n "$GITHUB_ARG" ]; then
      update_github_owner "$GITHUB_ARG"
    fi

    # Update github repository owner
    if [ -n "$CONFIG_ARG" ]; then
      update_config_repo "$CONFIG_ARG"
    fi

    # Update app repository name
    if [ -n "$APP_ARG" ]; then
      update_app_repo "$APP_ARG"
    fi

    # Update infra repository name
    if [ -n "$INFRA_ARG" ]; then
      update_infra_repo "$INFRA_ARG"
    fi

    # Add, commit and push changes to git
    echo "Adding, committing and pushing changed tfvars files to git remote ..."
    git_add_commit_push "Updating github repository variables for terraform"

  fi

  # Execute bootstrap commands within appropriate cloud folder
  cd "$CLOUD_ARG"

  # Create a temporary directory to hold generated files for this run
  # This is primarily used to avoid storing generated keys and secrets in the shell history
  create_tmp_dir


  # Iterate over environments for secret creation
  for env in dev qa prod
  do
      # If there is already local terraform state directory, delete it
      if [ -d ./.terraform ]; then
        rm -rf ./.terraform
      fi

      # Generate public and private SSH keys that ArgoCD can use to interact with GitHub repositories
      #   and then create an encrypted secret in Cloud Secrets Manager from the value
      gen_argocd_ssh_keys "$env"

      # Generate a fresh password for argocd admin account in the tmp directory
      #   and then create an encrypted secret in Cloud Secrets Manager from the value
      gen_argocd_admin_password "$env"

      github_add_public_ssh_key "$env"
  done

  # Create the terraform state bucket
  gcp_create_tfstate_bucket "$PROJECT_ARG-tfstate-$GITOPS_RUN_NUM"

  # If there is already local terraform state directory, delete it
  if [ -d ./.terraform ]; then
    rm -rf ./.terraform
  fi

  # Apply the base environment with terraform
  terraform_ipa bootstrap.plan

  # Clean up the tmp directory so we don't leave secrets laying around locally
  cleanup_tmp_dir

  # Leave us in the original invocation directory
  cd ..

  ;;
*)
  echo "---------------------"
  echo "No cloud selected..."
  echo "Please specify (aws|gcp) using the -c or --cloud flag"
  echo "For example: ./bootstrap.sh -c gcp"
  echo "  or ./bootstrap.sh --cloud=gcp"
  exit 1
  ;;
esac
