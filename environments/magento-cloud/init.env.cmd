function getProjectAndEnvironment {
    ENV_DATA=$(magento-cloud environment:info --format=csv --no-header)
    [[ $ENV_DATA =~ ^id,([^[:space:]]*) ]] && ENVIRONMENT=${BASH_REMATCH[1]}
    [[ $ENV_DATA =~ project,([a-z|A-Z|1-9]*) ]] && PROJECT=${BASH_REMATCH[1]}
}

function getPHPVersion {
    ENV_DATA=$(magento-cloud apps --format=csv --no-header --project=$PROJECT --environment=$ENVIRONMENT)
    [[ $ENV_DATA =~ php:([0-9|\.]*) ]] && PHP_VERSION=${BASH_REMATCH[1]}
}

function getDBVersion {
    ENV_DATA=$(magento-cloud services --format=csv --no-header --project=$PROJECT --environment=$ENVIRONMENT)
    if [[ $ENV_DATA =~ elasticsearch:([0-9|\.]*) ]]
    then
        ELASTICSEARCH_VERSION=${BASH_REMATCH[1]}
    fi
    if [[ $ENV_DATA =~ mysql:([0-9|\.]*) ]]
    then
        MARIADB_VERSION=${BASH_REMATCH[1]}
    fi
    if [[ $ENV_DATA =~ redis:([0-9|\.]*) ]]
    then
        REDIS_VERSION=${BASH_REMATCH[1]}
    fi
    if [[ $ENV_DATA =~ rabbitmq:([0-9|\.]*) ]]
    then
        RABBITMQ_VERSION=${BASH_REMATCH[1]}
    fi
}

function getComposerVersion {
    ENV_DATA=$(magento-cloud -q ssh 'composer --version' --project=$PROJECT --environment=$ENVIRONMENT)
    if [[ $ENV_DATA =~ 1\.([0-9]*)\. ]]
    then
        COMPOSER_VERSION=1
    else
        COMPOSER_VERSION=2
    fi
}

function checkMagentoCloudCli {
    if ! command -v magento-cloud &> /dev/null
    then
        echo -e "\033[33mmagento-cloud-cli could not be found.\033[0m"
        exit 1
    fi
}

checkMagentoCloudCli
getProjectAndEnvironment
getPHPVersion
getDBVersion
getComposerVersion

cat .env | \
sed "s/=magento-cloud/=magento2/g" | \
sed "s/%ELASTICSEARCH_VERSION%/${ELASTICSEARCH_VERSION:-7.6}/g" | \
sed "s/%MARIADB_VERSION%/${MARIADB_VERSION:-10.3}/g" | \
sed "s/%COMPOSER_VERSION%/${COMPOSER_VERSION:-1}/g" | \
sed "s/%PHP_VERSION%/${PHP_VERSION:-7.4}/g" | \
sed "s/%RABBITMQ_VERSION%/${RABBITMQ_VERSION:-3.8}/g" | \
sed "s/%REDIS_VERSION%/${REDIS_VERSION:-5.0}/g" | \
sed "s/%PROJECT%/${PROJECT}/g" | \
sed "s/%ENVIRONMENT%/${ENVIRONMENT}/g" > .env
