crontab -l > cron
# echo new cron into cron file
echo "0 10 * * * mackup backup --force >/dev/null 2>&1" > cron
# install new cron file
crontab cron
rm cron