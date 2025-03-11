#!/bin/bash -e
: "${taito_company:?}"
: "${taito_vc_repository:?}"
: "${taito_vc_repository_alt:?}"

if [[ ${taito_verbose:-} == "true" ]]; then
  set -x
fi

# Determine project short name
if [[ $taito_project_short != "aftemplate" ]]; then
  taito_project_short="${taito_project_short}"
else
  taito_project_short="${taito_vc_repository}"
fi
taito_project_short="${taito_project_short//-/}"
if [[ ! ${taito_project_short} ]] || \
   [[ "${#taito_project_short}" -lt 5 ]] || \
   [[ "${#taito_project_short}" -gt 10 ]] || \
   [[ ! "${taito_project_short}" =~ ^[a-zA-Z0-9]*$ ]]; then
  echo "Give a short version of the project name '${taito_vc_repository}'."
  echo "It should be unique but also descriptive as it might be used"
  echo "as a database name and as a database username for some databases."
  echo "No special characters."
  echo
  export taito_project_short=""
  while [[ ! ${taito_project_short} ]] || \
    [[ "${#taito_project_short}" -lt 5 ]] || \
    [[ "${#taito_project_short}" -gt 10 ]] || \
    [[ ! "${taito_project_short}" =~ ^[a-zA-Z0-9]*$ ]]
  do
    echo "Short project name (5-10 characters)?"
    read -r taito_project_short
  done
fi

function remove_empty_secrets () {
  sed -i -n '1h;1!H;${g;s/    secrets:\n    environment:/    environment:/;p;}' "$1"
}

remove_empty_secrets docker-compose.yaml
if [[ -f docker-compose-cicd.yaml ]]; then
  remove_empty_secrets docker-compose-cicd.yaml
fi
if [[ -f docker-compose-remote.yaml ]]; then
  remove_empty_secrets docker-compose-remote.yaml
fi

if [[ ${template_default_kubernetes} ]] || [[ ${kubernetes_name} ]]; then
  # Remove serverless-http adapter since Kubernetes is enabled
  if [[ -d ./server ]] && [[ -f ./server/src/server.ts ]]; then
    sed -i '/serverless/d' ./server/package.json
    sed -i '/serverless/d' ./server/src/function.ts
  fi

else
  # Remove helm.yaml since kubernetes is disabled
  rm -f ./scripts/helm*.yaml

  if [[ ${taito_provider} == "aws" ]]; then
    # Use aws policy instead of service account
    sed -i '/SERVICE_ACCOUNT_KEY/d' ./scripts/terraform.yaml
    sed -i '/id: ${taito_project}-${taito_env}-server/d' ./scripts/terraform.yaml
    sed -i '/-storage-serviceaccount/d' ./scripts/taito/project.sh
    sed -i '/-storage.accessKeyId/d' ./scripts/taito/project.sh
    sed -i '/-storage.secretKey/d' ./scripts/taito/project.sh
  else
    # Use service account instead of aws policy
    sed -i "/^      awsPolicy:\r*\$/,/^\r*$/d" ./scripts/terraform.yaml
    sed -i '/BUCKET_REGION/d' ./scripts/terraform.yaml
  fi

  # Remove storage service account
  # (most likely not required for storage access with serverless)
  sed -i '/$taito_project-$taito_env-storage/d' ./scripts/taito/project.sh
  sed -i '/-storage/d' ./scripts/terraform.yaml
fi

if [[ ${taito_provider} != "aws" ]]; then
  # Remove AWS specific stuff from implementation
  if [[ -d ./server ]] && [[ -f ./server/src/common/setup/config.ts ]]; then
    sed -i '/aws/d' ./server/src/common/setup/config.ts
    sed -i '/prettier-ignore/d' ./server/src/common/setup/config.ts
  fi
fi

echo
echo "Replacing project and company names in files. Please wait..."
find . -type f -exec sed -i \
  -e "s/aftemplate/${taito_project_short}/g" 2> /dev/null {} \;
find . -type f -exec sed -i \
  -e "s/airflow_template/${taito_vc_repository_alt}/g" 2> /dev/null {} \;
find . -type f -exec sed -i \
  -e "s/airflow-template/${taito_vc_repository}/g" 2> /dev/null {} \;
find . -type f -exec sed -i \
  -e "s/companyname/${taito_company}/g" 2> /dev/null {} \;
find . -type f -exec sed -i \
  -e "s/AIRFLOW-TEMPLATE/airflow-template/g" 2> /dev/null {} \;

echo "Generating unique random ports (avoid conflicts with other projects)..."
if [[ ! $ingress_port ]]; then ingress_port=$(shuf -i 8000-9999 -n 1); fi
if [[ ! $db_port ]]; then db_port=$(shuf -i 6000-7999 -n 1); fi
if [[ ! $www_port ]]; then www_port=$(shuf -i 5000-5999 -n 1); fi
if [[ ! $server_debug_port ]]; then server_debug_port=$(shuf -i 4000-4999 -n 1); fi
if [[ ! $client_free_port ]]; then client_free_port=$(shuf -i 3000-3990 -n 1); fi
if [[ ! $storage_port ]]; then storage_port=$(shuf -i 2000-2999 -n 1); fi
if [[ ! $uikit_port ]]; then uikit_port=$(shuf -i 1000-1999 -n 1); fi
sed -i "s/6006/${uikit_port}/g" \
  client/package.json &> /dev/null || :
sed -i "s/8888/${storage_port}/g" \
  docker-compose.yaml \
  scripts/taito/env-local.sh \
  scripts/taito/TAITOLESS.md &> /dev/null || :
sed -i "s/9996/$((client_free_port+0))/g" \
  docker-compose.yaml &> /dev/null || :
sed -i "s/9997/$((client_free_port+1))/g" \
  docker-compose.yaml &> /dev/null || :
sed -i "s/9998/$((client_free_port+2))/g" \
  docker-compose.yaml \
  scripts/taito/project.sh &> /dev/null || :
sed -i "s/4229/${server_debug_port}/g" \
  docker-compose.yaml \
  .vscode/launch.json \
  scripts/taito/project.sh scripts/taito/env-local.sh \
  scripts/taito/TAITOLESS.md www/README.md &> /dev/null || :
sed -i "s/7463/${www_port}/g" \
  docker-compose.yaml \
  scripts/taito/project.sh scripts/taito/env-local.sh \
  scripts/taito/TAITOLESS.md www/README.md &> /dev/null || :
sed -i "s/6000/${db_port}/g" \
  docker-compose.yaml \
  scripts/taito/project.sh scripts/taito/env-local.sh \
  scripts/taito/TAITOLESS.md www/README.md &> /dev/null || :
sed -i "s/9999/${ingress_port}/g" \
  docker-compose.yaml \
  scripts/terraform-dev.yaml \
  scripts/taito/project.sh scripts/taito/env-local.sh \
  scripts/taito/TAITOLESS.md www/README.md &> /dev/null || :

./scripts/taito-template/common.sh
echo init done
