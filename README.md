# nextcloud-backup
скрипт производит бакап данных и скидывает их на удаленный сервер

## FEATURES: 
Progress bar, потоковое сжатие, TAR.GZ инкрементный архив

## REQUIREMENTS:
GNU Core Utilities, mysql, mysqldump, pv, nextcloud сервер ,SAMBA сервер

Можно отказатся от монтирования папки через SAMBA закоментив соотвествующую строку и хранить все локально.

```
sudo mount  $MNT_FOLDER $TARGET_FOLDER -o rw,user=$MNT_USER,pass=$MNT_PASSWORD,file_mode=0644,dir_mode=0777
...
sudo umount /mnt/backups

```
Можно сделать CRON работу раз в неделю архивы будут лежать по папкам с годом и номером месяца 
Задача Cron должна исполнятся от ROOT если используется SAMBA. Если нет - можно использовать пользователя имеющего доступ до папок и убрать в скрипте все sudo в создании задачи ниже

```
chmod +x /home/user/nextcloud-backup/nextcloud_backup.sh
sudo crontab -l > current_cron
sudo cat >> current_cron << EOF
@weekly sh /home/user/nextcloud-backup/nextcloud_backup.sh  > /dev/null 2>&1 #Nextcloud backup
EOF
sudo crontab < current_cron
sudo rm -f current_cron
```
