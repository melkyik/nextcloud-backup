#!/bin/sh

CONFIG_FILE_NAME="/home/igor/nextcloud-backup/nextcloud_backup.conf"

OK=0
ERROR_CONFIG_FILE_UNAVAILABLE=1

ERROR_COULD_NOT_SET_MAINTENANCE_MODE=2

ERROR='\033[0;31m'
WARN='\033[1;33m'
INFO='\033[0;32m'
TIME='\033[0;36m'
NC='\033[0m'

log()
{
  TIMESTAMP="$TIME$(date +%Y-%m-%d\ %H:%M:%S)$NC"
  if  [ $2 -e $ERROR ]; then
    echo "$TIMESTAMP $ERROR$1$NC" 1>&2
  elif [ -z  "$2" ]
  then
    echo "$TIMESTAMP $INFO$1$NC"
  else
    echo "$TIMESTAMP $2$1$NC"
  fi
}

log_error()
{
  log $1 $ERROR
}

load_config_file()
{
  log "Loading config file"
  . $CONFIG_FILE_NAME 2> /dev/null

  if [ $? -ne 0 ]; then
    log_error "Could not find config file $CONFIG_FILE_NAME";
    exit $ERROR_CONFIG_FILE_UNAVAILABLE;
  fi
  log "Successfully loaded config file"
}

get_date()
{
  DATETIME=$(date +"%Y-%m-%d-%s")
  YEAR=$(echo $DATETIME  | cut --delimiter=- -f1)
  MONTH=$(echo $DATETIME  | cut --delimiter=- -f2)
}
prepare_target_directory()
{

   mkdir -p "$TARGET_FOLDER/$YEAR/$MONTH"

}
set_maintenance_mode()
{
  if [ $1 -eq 1 ]; then
    log "Enable maintenance mode"
    php occ maintenance:mode --on
  else
    log "Disable maintenance mode"
    php occ maintenance:mode --off
  fi

  if [ $? -ne 0 ]; then
    log_error "Could not set maintenance mode";
    exit $ERROR_COULD_NOT_SET_MAINTENANCE_MODE
  fi
}
set_maintenance_mode_via_config()
{
  if [ $1 -eq 1 ]; then
    log "Enable maintenance mode by modifying $NEXTCLOUD_CONFIG_FILE"
    sed --in-place --regexp-extended\
    --expression="s/'maintenance' => (true|false),/'maintenance' => true,/g" $NEXTCLOUD_CONFIG_FILE
  else
    log "Disable maintenance mode by modifying $NEXTCLOUD_CONFIG_FILE"
    sed --in-place --regexp-extended\
    --expression="s/'maintenance' => (true|false),/'maintenance' => false,/g" $NEXTCLOUD_CONFIG_FILE
  fi
}

backup_web_directory()
{
  log "Backing up web directory"

  snar_file="$TARGET_FOLDER/$YEAR/$MONTH/$TARGET_FILE_WEB.snar"
  archive_file="$TARGET_FOLDER/$YEAR/$MONTH/$DATETIME-$TARGET_FILE_WEB.tar.gz"
  log "Target: $archive_file"

  tar --create --gzip $NEXTCLOUD_WEB_DIRECTORY\
      --exclude=$NEXTCLOUD_DATA_DIRECTORY\
      --listed-incremental="$snar_file"|pv > $archive_file
# create_checksum $archive_file
}

backup_data_directory()
{
  log "Backing up data directory"

  snar_file="$TARGET_FOLDER/$YEAR/$MONTH/$TARGET_FILE_DATA.snar"
  archive_file="$TARGET_FOLDER/$YEAR/$MONTH/$DATETIME-$TARGET_FILE_DATA.tar.gz"
  log "Target: $archive_file"

  tar --create --gzip $NEXTCLOUD_DATA_DIRECTORY\
      --listed-incremental="$snar_file" |pv > $archive_file

# create_checksum $archive_file
}

backup_database()
{
  log "Backing up database"

  archive_file="$TARGET_FOLDER/$YEAR/$MONTH/$DATETIME-$TARGET_FILE_DB.sql.gz"
  log "Target: $archive_file"

  mysqldump -u$MDB_USER -p$MDB_PASSWORD $DB_NAME -h $DB_HOST --single-transaction | gzip -c |pv > $archive_file
#  create_checksum $archive_file
}

create_checksum()
{
   log "Creating md5 checksum for $1"
   md5sum $1 >> "$TARGET_FOLDER/$YEAR/$MONTH/MD5SUM"
}

load_config_file
get_date
prepare_target_directory
MNT_USER="user"
MNT_PASSWORD="123456789"

cd $NEXTCLOUD_WEB_DIRECTORY
sudo mount  //10.10.2.104/backups /mnt/backups -o rw,user=$MNT_USER,pass=$MNT_PASSWORD,file_mode=0777,dir_mode=0777
set_maintenance_mode_via_config 1
prepare_target_directory
backup_database
backup_web_directory
backup_data_directory
set_maintenance_mode_via_config 0
sudo umount /mnt/backups

exit $OK
