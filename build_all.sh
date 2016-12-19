#!/bin/bash

USER='xataz'
DOCKER_PUSH=$1

CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CBLUE="${CSI}1;34m"

for f in $(find . -maxdepth 1 -type d | grep -v '^.$' | grep -v '.git' | sed 's|./||'); do
    if [ -d $f ]; then
        if [ -e $f/build.sh ]; then
            chmod +x $f/build.sh
            echo 
            ./$f/build.sh $DOCKER_PUSH
        else
            for dockerfile in $(find $f -name Dockerfile); do
                FOLDER=$(dirname $dockerfile)
                LOG_FILE="/tmp/${f}_$(date +%Y%m%d).log"
                echo -ne "Build $dockerfile with context $FOLDER on tmp-build [${CYELLOW}..${CEND}]\r"
                docker build -f $dockerfile -t tmp-build $FOLDER > $LOG_FILE 2>&1
                if [ $? != 0 ]; then
                    echo -ne "Build $dockerfile with context $FOLDER on tmp-build [${CRED}KO${CEND}]"
                    cat $LOG_FILE
                else
                    echo -e "Build $dockerfile with context $FOLDER on tmp-build [${CGREEN}OK${CEND}]"
                    for tag in $(grep "tags=" $dockerfile | cut -d'"' -f2); do
                        echo -ne "Tags tmp-build to ${USER}/${f}:${tag} [${CYELLOW}..${CEND}]\r"
                        docker tag tmp-build ${USER}/${f}:${tag}
                        if [ $? != 0 ]; then
                            echo -ne "Tags tmp-build to ${USER}/${f}:${tag} [${CRED}KO${CEND}]"
                        else
                            echo -ne "Tags tmp-build to ${USER}/${f}:${tag} [${CGREEN}OK${CEND}]"
                            if [ "$DOCKER_PUSH" == "push" ]; then
                                echo -ne "Push ${USER}/${f}:${tag} [${CYELLOW}..${CEND}]\r"
                                docker push ${USER}/${f}:${tag} > $LOG_FILE 2>&1
                                if [ $? != 0 ]; then
                                    echo -ne "Push ${USER}/${f}:${tag} [${CRED}KO${CEND}]"
                                    cat $LOG_FILE
                                else
                                    echo -ne "Push ${USER}/${f}:${tag} [${CGREEN}OK${CEND}]"
                                fi
                            fi
                        fi
                    done
                fi
            done
            if [ $(docker images | grep tmp-build) -eq 0 ]; then docker rmi tmp-build; fi
        fi
        
    fi
done