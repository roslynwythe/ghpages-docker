# GitHub Pages Docker

This repo contains the source code (i.e. Dockerfile and related scripts) required to build a Docker image that is pegged to the dependency versions used by GitHub Pages. It is based on the official [Jekyll Docker image](https://github.com/envygeeks/jekyll-docker). The resulting Docker image is hosted on [Hack for LA’s Docker Hub repo](https://hub.docker.com/r/hackforlaops/ghpages/tags).

This Docker image is specifically designed to run a local Jekyll server for developing and testing the Hack for LA organization’s website. It is not intended for deployment. However, the image can be used by anyone who requires a local development environment that mirrors GitHub Pages.

More detailed technical information can be find on this repo's [wiki](https://github.com/hackforla/ghpages-docker/wiki).


## Usage instructions

### If you are a member of the Hack for LA organization:
This repo uses a GitHub Action to build and push the Docker image to the [hackforlaops/ghpages repo](https://hub.docker.com/r/hackforlaops/ghpages/tags) on Docker Hub. The newly-built image will replace the previous version, and appear with the tag `latest`. The build-and-push action can be triggered in one of two ways:
1. Automatically, whenever a new commit is pushed to the repo. (*Unless* the commit only contains changes to the `.github` directory, which is ignored.) This means that a new image will be built automatically any time the Dockerfile is updated to match a new version of Ruby or Jekyll being used by GitHub Pages.
2. Manually, by navigating to the **Actions** tab in the menu bar at the top of the repo, clicking on the **Publish Docker Image** workflow in the list of workflows on the left, and then clicking the **Run Workflow** button on the right. This will build and push a new image whether any changes have been made or not.

### If you are NOT a member of Hack for LA:
Hack for LA's website is run locally using `docker compose`. To use this image in the same way for your own Jekyll-based projects, do the following: 
1. Create or modify a `docker-compose.yml` file in the root of your website directory with the following lines. (Note that you should replace `<your-name>` with whatever you would like your Docker container to be called.)
```
version: "3"
services:
  <your-name>:
    image: hackforlaops/ghpages:latest
    container_name: <your-name>
    command: jekyll serve --force_polling --livereload --config _config.yml,_config.docker.yml -I
    environment:
      - JEKYLL_ENV=docker
    ports:
      - 4000:4000
      - 35729:35729
    volumes:
      - .:/srv/jekyll
```
2. Run `docker compose up`.

### Licensing

This code is made available under the [GNU General Public License v2.0](https://github.com/hackforla/ghpages-docker/blob/main/LICENSE)

*this readme file sourced from [Jessica Sand](http://jessicasand.com/other-stuff/just-enough-docs/)*
