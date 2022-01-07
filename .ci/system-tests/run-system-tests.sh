#!/bin/bash
#########################################################################################
#    Script to run the System Tests  for HIRS TPM 2.0 Provisoner
#
#########################################################################################
aca_container=hirs-aca1
tpm2_container=hirs-provisioner1-tpm2
testResult="passed";
issuerCert=../setup/certs/ca.crt

# Source files for Docker Variables and helper scripts
. ./.ci/docker/.env

set -a

echo "********  Setting up for HIRS System Tests for TPM 2.0 ******** "

# Start System Testing Docker Environment
cd .ci/docker

docker-compose -f docker-compose-system-test.yml up -d

cd ../system-tests
source sys_test_common.sh

aca_container_id="$(docker ps -aqf "name=$aca_container")"
tpm2_container_id="$(docker ps -aqf "name=$tpm2_container")"

echo "ACA Container ID is $aca_container_id and has a status of $(CheckContainerStatus $aca_container_id)";
echo "TPM2 Provisioner Container ID is $tpm2_container_id and has a status of  $(CheckContainerStatus $tpm2_container_id)";

# Install HIRS provioner and setup tpm2 emulator
docker exec $tpm2_container /HIRS/.ci/setup/setup-tpm2provisioner.sh

# ********* Execute system tests here, add tests as needed ************* 
echo "******** Setup Complete Begin HIRS System Tests ******** "

source aca_policy_tests.sh

echo "******** HIRS System Tests Complete ******** "

# collecting ACA logs for archiving
echo "Collecting ACA logs ....."
docker exec $aca_container mkdir -p /HIRS/logs/aca/;
docker exec $aca_container cp -a /var/log/tomcat/. /HIRS/logs/aca/;
docker exec $aca_container chmod -R 777 /HIRS/logs/;
echo "Collecting provisioner logs"
docker exec $tpm2_container mkdir -p /HIRS/logs/provisioner/;
docker exec $tpm2_container cp -a /var/log/hirs/provisioner/. /HIRS/logs/provisioner/;
docker exec $tpm2_container chmod -R 777 /HIRS/logs/;

# Display container log
echo ""
echo "===========HIRS Tests and Log collection complete ==========="
#docker logs $tpm2_container_id 

echo ""
echo "End of System Tests for TPM 2.0, cleaning up..."
echo ""
# Clean up services and network
docker-compose down

# Clean up dangling containers
echo "Cleaning up dangling containers..."
echo ""
docker ps -a
echo ""
docker container prune --force
echo ""
echo "New value of test status is ${TEST_STATUS}"
# Return container exit code
if [[ ${TEST_STATUS} == "0" ]]; then
    echo "SUCCESS: System Tests for TPM 2.0 passed"
    echo "TEST_STATUS=0" >> $GITHUB_ENV
    exit 0;
  else
    echo "FAILURE: System Tests for TPM 2.0 failed"
    echo "TEST_STATUS=1" >> $GITHUB_ENV
    exit 1  
fi