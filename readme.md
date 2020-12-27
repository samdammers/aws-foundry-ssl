# AWS Foundry VTT Deployment with SSL Encryption

_Deploys Foundry VTT with SSL encryption in AWS using CloudFormation (Beginner Friendly)_

This is an upgraded version of the [original](https://www.reddit.com/r/FoundryVTT/comments/iurf7h/i_created_a_method_to_automatically_deploy_a/) beginner friendly automated AWS deployment Lupert and I worked on. We did some tinkering and it now handles setup and creation of AWS resources, in addition to fully configuring reverse proxy and certificate renewal. **tldr**: You can now use audio and video in Foundry to your heart's content!

Head to the [**wiki page**](https://github.com/cat-box/aws-foundry-ssl/wiki) for the full instructions, and remember: **READ EVERY. SINGLE. PAGE**.

# Additions

Added an api to enable me to whitelist player IP's for the s3 static assets.
This was done so I didn't leave public assets I bought from DnD Map creators

Also added a stop/start server api so I can save costs by shutting it down between sessions