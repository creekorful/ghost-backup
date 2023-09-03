#!/usr/bin/env bash

set -euxo pipefail

# Base variables
INSTALL_PATH="$1"

BACKUP_ROOT_PATH="$HOME/.ghost-backup"
CONFIG_PATH="$HOME/.config/ghost-backup.json"

GHOST_CMD="/usr/local/bin/ghost"
TAR_CMD="/usr/bin/tar"
MYSQLDUMP_CMD="/usr/bin/mysqldump"
MKDIR_CMD="/usr/bin/mkdir"
JQ_CMD="/usr/bin/jq"
AWS_CMD="/usr/bin/aws"
RM_CMD="/usr/bin/rm"

# Bootstrap base directories
$MKDIR_CMD -p "$BACKUP_ROOT_PATH"

# 1. Stop ghost instance
$GHOST_CMD stop --dir "$INSTALL_PATH"

# 2. backup file system
$TAR_CMD cf "$BACKUP_ROOT_PATH/content.tar.gz" -C "$INSTALL_PATH" .

# 3. backup MySQL database
MYSQL_USER=$($JQ_CMD -r .database.connection.user "$INSTALL_PATH/config.production.json")
MYSQL_PASSWORD=$($JQ_CMD -r .database.connection.password "$INSTALL_PATH/config.production.json")
MYSQL_DATABASE=$($JQ_CMD -r .database.connection.database "$INSTALL_PATH/config.production.json")

$MYSQLDUMP_CMD -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" > "$BACKUP_ROOT_PATH/database.sql"

# 4. compress everything together
BACKUP_FILENAME="backup-$(date +"%Y-%m-%d").tar.gz"
$RM_CMD -f "$BACKUP_ROOT_PATH/$BACKUP_FILENAME"

$TAR_CMD czf "$BACKUP_ROOT_PATH/$BACKUP_FILENAME" -C "$BACKUP_ROOT_PATH" content.tar.gz database.sql
rm "$BACKUP_ROOT_PATH/content.tar.gz" "$BACKUP_ROOT_PATH/database.sql"

# 5. upload to S3
AWS_ENDPOINT_URL=$($JQ_CMD --arg BASE_CONFIG_KEY "$INSTALL_PATH" -r ".[\$BASE_CONFIG_KEY].aws.endpoint" "$CONFIG_PATH")
AWS_BUCKET=$($JQ_CMD --arg BASE_CONFIG_KEY "$INSTALL_PATH" -r ".[\$BASE_CONFIG_KEY].aws.bucket" "$CONFIG_PATH")

$AWS_CMD s3 --endpoint-url "$AWS_ENDPOINT_URL" cp "$BACKUP_ROOT_PATH/$BACKUP_FILENAME" "s3://$AWS_BUCKET/$BACKUP_FILENAME"

# 6. restart ghost instance
$GHOST_CMD start --dir "$INSTALL_PATH"