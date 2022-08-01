#!/usr/bin/env bash

[ -d 'config' ] || {
    echo "没有找到配置文件, 请执行应用注册 Action."
    exit 1
}

poetry run python crypto.py d
poetry run python task.py
poetry run python crypto.py e
