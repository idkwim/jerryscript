# Copyright 2015 Samsung Electronics Co., Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

MAKE="$1"
shift

OUT_DIR="$1"
shift

TARGETS="$1"
shift

PARSE_ONLY_TESTING_PATHS="./tests/benchmarks/jerry"
FULL_TESTING_PATHS="./tests/jerry ./tests/jerry-test-suite/precommit_test_list"

echo -e "\nBuilding...\n\n"
$MAKE STATIC_CHECK=ON build || exit 1
echo -e "\n================ Build completed successfully. Running precommit tests ================\n"
echo -e "All targets were built successfully. Starting unit tests' run.\n"
$MAKE unittests_run || exit 1
echo -e "\nUnit tests completed successfully. Starting full testing.\n"

RUN_IDS=""

for TARGET in $TARGETS
do
 ENGINE=$OUT_DIR/$TARGET/jerry
 LOGS_PATH_PARSE_ONLY=$OUT_DIR/$TARGET/check_parse_only
 LOGS_PATH_FULL=$OUT_DIR/$TARGET/check

 # Parse-only testing
 INDEX=0
 for TESTS_PATH in "./tests/benchmarks/jerry"
 do
   ./tools/runners/run-precommit-check-for-target.sh $ENGINE $LOGS_PATH_PARSE_ONLY/$INDEX $TESTS_PATH --parse-only &
   RUN_IDS="$RUN_IDS $!";
   INDEX=$((INDEX + 1))
 done

 # Full testing
 INDEX=0
 for TESTS_PATH in "./tests/jerry" "./tests/jerry-test-suite/precommit_test_list"
 do
   ./tools/runners/run-precommit-check-for-target.sh $ENGINE $LOGS_PATH_FULL/$INDEX $TESTS_PATH &
   RUN_IDS="$RUN_IDS $!";
   INDEX=$((INDEX + 1))
 done
done

RESULT_OK=1
for RUN_ID in $RUN_IDS
do
  wait $RUN_ID || RESULT_OK=0
done;
[ $RESULT_OK -eq 1 ] || exit 1

echo -e "Full testing completed successfully\n\n================\n\n"
