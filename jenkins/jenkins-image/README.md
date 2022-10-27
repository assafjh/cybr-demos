# jenkins-image
This folder contains the definitions for creating the custom Jenkins image used for this demo.
### Files
- Dockerfile - the image assembly commands.
- plugins.txt - a list of all the Jenkins plugins that is installed on the image.
- casc.yml - the custom Jenkins configuration, is used by the ***Configuration as Code*** plugin.
- build_image.sh - bash script to build the image and push it to the image repository.