# save current cron to a new file
crontab -l > cron

# echo new cron into cron file
echo "0 10 * * * /usr/local/bin/mackup backup --force >/tmp/stdout.log 2>/tmp/stderr.log" > cron

# install new cron file
crontab cron
rm cron
