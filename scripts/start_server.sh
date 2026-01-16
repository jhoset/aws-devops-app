#!/bin/bash
set -e

systemctl enable httpd
systemctl start httpd
