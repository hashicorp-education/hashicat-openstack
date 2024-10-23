#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: Apache-2.0

# Script to deploy a very simple web application.
# The web app has a customizable image and some text.

cat << EOM > /home/ubuntu/www/index.html
Meow ${PLACEHOLDER} !!!
EOM

echo "Script complete."
