#!/bin/bash

#set -x

if [ "$2" == "" ]; then
    echo "Usage: $0 <module> <version> [path]"
    echo "Example: $0 oak-core 1.8-SNAPSHOT OSGI-INF/org.apache.jackrabbit.oak.plugins.index.datastore.DataStoreTextProviderService.xml"
    echo
    echo "Without a specified path, all changed xml files are diffed."
    exit 1
fi

MODULE="$1"
VERSION="$2"
FILE_PATH="$3"

ARTIFACT_FILENAME="${MODULE}-${VERSION}.jar"
NEW_ARTIFACT="${MODULE}/target/${ARTIFACT_FILENAME}" 
OLD_ARTIFACT="${HOME}/.m2/repository/org/apache/jackrabbit/${MODULE}/${VERSION}/${ARTIFACT_FILENAME}"

COMPARISON_WORK_DIR=".comparison"

rm -rf "${COMPARISON_WORK_DIR}/new"
mkdir -p "${COMPARISON_WORK_DIR}/new"
echo "Building ${MODULE} (see ${COMPARISON_WORK_DIR}/mvn.log)"
mvn package -pl "${MODULE}" -DskipTests > "${COMPARISON_WORK_DIR}/mvn.log"
unzip -q "${NEW_ARTIFACT}" -d "${COMPARISON_WORK_DIR}/new"

if [[ ! -d "${COMPARISON_WORK_DIR}/old" ]]; then
    mkdir -p "${COMPARISON_WORK_DIR}/old"
    unzip -q "${OLD_ARTIFACT}" -d "${COMPARISON_WORK_DIR}/old" 
fi

if [ "${FILE_PATH}" == "" ]; then
    CHANGED_FILES=$(bnd diff -r ${NEW_ARTIFACT} ${OLD_ARTIFACT} | grep 'OSGI-INF' | grep '.xml' | grep -E 'MAJOR|REMOVED' | awk '{print $3}' | sed -E 's/(.+)\.([A-Z].+)/\1@\2/' | sort -t'@' -dk2 | tr '@' '.')
else
    CHANGED_FILES="${FILE_PATH}"
fi

echo > "${COMPARISON_WORK_DIR}/diffs.log"
for file in $CHANGED_FILES; do
    (
        cd "${COMPARISON_WORK_DIR}"

        FILE_DIR=$(dirname "${file}")
        FILE_NAME=$(basename "${file}" '.xml')
        WILDCARD_PATH="${FILE_DIR}/${FILE_NAME}*.xml"
        NEW_PATH=$(ls new/$WILDCARD_PATH)
        OLD_PATH=$(ls old/$WILDCARD_PATH)

        if [ ! -f xmldiffs.py ]; then
            curl -O https://raw.githubusercontent.com/joh/xmldiffs/ba0d1dc79d3b2972c37796f9effa027cd18607ce/xmldiffs.py
        fi

        # apply some normalizations to account for common (meaningless) differences
        for i in "${OLD_PATH}" "${NEW_PATH}"; do
            sed -i'.orig' -E 's/ servicefactory="false"//g'    "${i}"
            sed -i'.bak'  -E 's/type="String" //g'             "${i}"
            sed -i'.bak'  -E 's/( id=".*)\$Configuration/\1/g' "${i}"
            sed -i'.bak'  -E 's/ xmlns:(scr|metatype)=".*"//g' "${i}" && \
            sed -i'.bak'  -E 's/(<\/?)(scr|metatype):/\1/g'    "${i}"
            echo "${i}" | grep -q 'metatype' && sed -i'.bak'  -E 's/(name|description)=".*"/\1="\[\[noise\]\]"/g' "${i}"
        done
        mkdir -p "diffs/${FILE_DIR}"
        DIFF_FILE="diffs/${FILE_DIR}/${FILE_NAME}.diff"
        python xmldiffs.py "${OLD_PATH}" "${NEW_PATH}" > "${DIFF_FILE}"
        
        cat "${DIFF_FILE}" >> diffs.log
        echo >> diffs.log
    )
done

less "${COMPARISON_WORK_DIR}/diffs.log" 
