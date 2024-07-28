# Upgrading from a previous version

Minor updates should be installable in-place via the Foundry admin screen. **Major Foundry updates need some planning**.

From the admin interface, you can test the major upgrade ahead of time. On the version update screen, there's an option to test your add-ons for compatibility so you can find out what will work and what won't. Many add-ons will need to be updated as Foundry versions often make pretty drastic changes to their script code.

When upgrading major versions, make sure to back up all the Foundry data from your existing EC2 instance (such as transferring it to your computer via SCP). Once you've downloaded all your foundry worlds and user data, make a note of all the add-ons you use as you'll very likely need to reinstall them manually. Many add-ons change repositories, dependencies, or simply aren't compatible as the project is abandoned. Once you're sure you've got everything, manually stop the EC2 server. Then, deploy a new CloudFormation stack with the new version of Foundry. After entering your license key, re-upload your world data, and then manually reinstall your plugins. If something goes awry, you can always stop the new EC2 and start the old EC2.

Your worlds should be okay to bring over, and it should prompt you to upgrade the save format if it's changed in any way. Note that this is an irreversible process, so keep a back-up of the old version at least for a little while!

Once you're happy that the new version is working as you wish, you can tear down the _old_ CloudFormation stack.

You can do a major version upgrade in-place on your current server, but that's at your own initiative as it can be risky.

### Transferring Worlds and Data

Downloading the `/foundrydata` folder from your old EC2 in anticipation of uploading it to another should suffice.

If you're using SCP you'll need to do two things after uploading to your new instance:

1. Set permissions back to `foundry`
2. Restart the `foundry` service

In the `/aws-foundry-ssl/utils` folder, you can run:

`sudo sh ./fix_folder_permissions.sh`, and then
`sudo sh ./restart_foundry.sh`

If you get permissions errors, you may also need to run just the `./fix_folder_permissions.sh` script after adding your Foundry license, but _before_ you transfer files. By default Foundry creates more restrictive folder permissions.
