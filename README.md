# discord_minecraft_release_bot
A Discord Bot which checks for whether a new Minecraft release or snapshot has been released and makes a post via Discord Webhook.

The script will extract the "snapshot" and "release" version information from the Mojang version manifest file used by the Minecraft launcher and compare it against a cached copy. If it detects a variation, a message will be posted to Discord.


# Installation Instructions
1. Set up a Discord Webhook in your channel. See: https://support.discordapp.com/hc/en-us/articles/228383668-Intro-to-Webhooks
2. Add your webhook URL to the DISCORD_WEBHOOK_URL variable within the script. 
_Bash version: Ensure the URL is wrapped around single quotes inside the variable, or the curl command will not work. (An example is provided within the script.)_
3. Add the script to cron to run at your convenience, but please use discretion and don't be excessive.


# Notes
- The default bot username is "Minecraft" but this can be changed by modifying the DISCORD_USERNAME variable.
- The output message is also configurable if you want, by changing the contents of DISCORD_MESSAGE towards the end of the script.
- You can modify the temporary location where the script should store its cache file in the TMP variable.

# Requirements
curl: https://curl.haxx.se/

jq: https://stedolan.github.io/jq/
