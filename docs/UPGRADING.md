# Upgrading from a previous version

Minor updates should be installable in-place via the Foundry admin screen. **Major Foundry updates need some planning**.

From the admin interface, you can test the major upgrade ahead of time. On the version update screen, there's an option to test your add-ons for compatibility so you can find out what will work and what won't. Many add-ons will need to be updated as Foundry versions often make pretty drastic changes to their script code.

When upgrading major versions, make sure to back up all the Foundry data from your existing EC2 instance (such as transferring it to your computer via SCP). Once you've downloaded all your foundry worlds and user data, make a note of all the add-ons you use as you'll very likely need to reinstall them manually. Many add-ons change repositories, dependencies, or simply aren't compatible as the project is abandoned. Once you're sure you've got everything, manually stop the EC2 server.

Then, deploy a new CloudFormation stack with the new version of Foundry, making sure to set a different IAM Admin Username (ie. if you previously used the default `FoundryAdmin`, it should be changed to something else for the new stack, for example by adding the major Foundry version to the name).

Once deployed, you'll need to:

- SSH into the server and set the permissions so you can upload via SCP with `sudo chmod -R 755 /foundrydata/Data/worlds`
- Then, re-upload your world data to this folder via SCP
- Once complete, run `sudo /aws-foundry-ssl/utils/fix_folder_permissions.sh`
- Restart the Foundry server with `sudo /aws-foundry-ssl/utils/restart_foundry.sh`
- Finally, enter your license key into Foundry, set your admin password, and then _manually_ reinstall your plugins

At any point if something goes awry, you can always stop the new EC2 and start the old EC2 to test.

Once up and running, Foundry should prompt you to upgrade the save format if it's changed in any way. Note that this is an irreversible process, so keep a back-up of the old version at least for a little while!

When you're happy that the new server and Foundry version is working as you wish, you can tear down the _old_ CloudFormation stack. Make sure to update the scheduler if you're using it.

_Note: You can do a major version upgrade in-place on your current server, but that's at your own initiative as it can be risky._
