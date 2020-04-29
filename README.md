# cloudflare-ddns-updater for ipv4 only
Quick bash script to update cloudflare's dynamic dns
Optimized For Mainland Chinese users
  - Use ipv4.icanhazip.com to get local IPv4 IPAddr
  - Use myip.ipip.net to get detailed IPaddr Info
  - Add Update Time

will update IP if change is detected (run it periodically in crontab). --force and --log available. 
--log logs to ~/log-cfddns
--force force to update Cloudflare's Record
