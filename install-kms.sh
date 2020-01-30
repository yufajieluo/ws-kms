#!/bin/bash

DOCKER_IMAGE_NAME=ws-vlmcsd
DOCKER_CONTAINER_NAME=ws-kms
DOCKER_KMS_PORT=1688

COLOR_ERROR="31m"
COLOR_SUCCESS="32m"
COLOR_WARNING="33m"

function print_color()
{
    echo -e "\033[${1}${2}\033[0m"
}

function check()
{
    ${2}
    ret=${?}
    if [ ${ret} -eq 0 ];
    then
        print_color ${COLOR_SUCCESS} "[${1}]环境已准备好."
    else
        print_color ${COLOR_ERROR} "[${1}]环境未准备好，请先安装[${1}]."
    fi
    return ${ret}
}

function check_docker()
{
    check docker "docker -v"
}

function options_port()
{
    while true
    do
        output=`netstat -anp | grep LISTEN | grep ${DOCKER_KMS_PORT}`
        if [ -n "${output}" ];
        then
            let DOCKER_KMS_PORT+=10
        else
            break
        fi
    done    
}

function clear_env()
{
    docker stop ${DOCKER_CONTAINER_NAME}
    docker rm ${DOCKER_CONTAINER_NAME}
    docker rmi ${DOCKER_IMAGE_NAME}
}

function build_image()
{
    docker build -f Dockerfile -t ${DOCKER_IMAGE_NAME} .
}

function start_container()
{
    docker run -d \
        --name ${DOCKER_CONTAINER_NAME} \
        -p ${DOCKER_KMS_PORT}:1688 \
        ${DOCKER_IMAGE_NAME}
}

function main()
{
    print_color ${COLOR_WARNING} "检查本地Docker环境开始..."
    check_docker
    if [ ${?} -ne 0 ];
    then
        print_color ${COLOR_ERROR} "退出"
        exit 1
    fi
    
    print_color ${COLOR_WARNING} "清理Docker环境开始..."
    clear_env
    print_color ${COLOR_SUCCESS} "清理Docker环境完成."
    
    print_color ${COLOR_WARNING} "初始化本地端口开始..."
    options_port
    print_color ${COLOR_SUCCESS} "初始化本地端口完成."
    
    print_color ${COLOR_WARNING} "编译vlmcsd镜像开始..."
    build_image
    print_color ${COLOR_SUCCESS} "编译vlmcsd镜像完成."
    
    print_color ${COLOR_WARNING} "启动容器开始..."
    start_container
    print_color ${COLOR_SUCCESS} "启动容器完成."
    
    print_color ${COLOR_SUCCESS} "KMS Server 启动成功："
    print_color ${COLOR_SUCCESS} "KMS端口 : ${DOCKER_KMS_PORT}"
}

main
