# Note: this Dockerfile uses a multistage build to prevent the final image from being unnecessarily large. During a build, each RUN command
# creates a new layer that persists into the final image, even if packages installed early on are later uninstalled before 
# the end of the Dockerfile. To avoid this, most of the installation takes place during stage one, then only the github-pages gem is
# copied over into stage 2.

###
### BUILD STAGE 1
###

# The FROM command specifies a base image to start with. We're using an Alpine Linux base because it's small (around 5MB), together with a Ruby installation 
# that matches GitHub Pages' current Ruby version (2.7.3, as of 06/13/2022)
FROM ruby:2.7.3-alpine3.13 AS build
LABEL maintainer "Jordon Bedwell <jordon@envygeeks.io>"


# Set Ruby ENV variables
ENV GEM_BIN=/usr/gem/bin
ENV GEM_HOME=/usr/gem

# Linux package installation
# (Some of the following are needed to install the github-pages gem later on, 
# but some are likely not needed at all; maybe a good future project to sift out the ones that aren't.)
#
# Install development packages (via apk --> "Alpine Package Keeper") 
RUN apk --no-cache add \
  zlib-dev \
  libffi-dev \
  build-base \
  libxml2-dev \
  imagemagick-dev \
  readline-dev \
  libxslt-dev \
  libffi-dev \
  yaml-dev \
  zlib-dev \
  vips-dev \
  vips-tools \
  sqlite-dev \
  cmake

# Install main packages
RUN apk --no-cache add \
  linux-headers \
  openjdk8-jre \
  less \
  zlib \
  libxml2 \
  readline \
  libxslt \
  libffi \
  git \
  nodejs \
  tzdata \
  shadow \
  npm \
  libressl \
  yarn

# Update currently installed Gems
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN unset GEM_HOME && unset GEM_BIN && \
  yes | gem update --system

# Install github-pages gem. 
# This gem bundles all dependencies required by GitHub Pages, including Jekyll.
#
# (When no version number is specified, it will install the most recent version available. (v226, as of 06/13/2022)
# To specify a version, use "gem install github-pages:<version_number>")
RUN gem install github-pages -- \
    --use-system-libraries


###
### BUILD STAGE 2
###

FROM ruby:2.7.3-alpine3.13

# Copy shell scripts from the Dockerfile directory into the root of the new build stage. 
# (It may be possible to create an image without these; maybe a future project to look into removing them.)
COPY copy/all /

# Set Ruby ENV variables again for new build stage
ENV GEM_BIN=/usr/gem/bin
ENV GEM_HOME=/usr/gem

# Set ENV variables for new build stage
ENV JEKYLL_BIN=/usr/jekyll/bin

# Set system ENV variables
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV TZ=America/Chicago
ENV PATH="$JEKYLL_BIN:$PATH"
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US

# Install bash and su-exec. These are required by the shell scripts we copied over right after starting build stage 2.
RUN apk --no-cache add \
  bash \
  su-exec

# Copy the github-pages gem we installed during stage 1 into an identical folder within the new build stage.
COPY --from=build /usr/gem/ /usr/gem/

RUN addgroup -Sg 1000 jekyll
RUN adduser  -Su 1000 -G \
  jekyll jekyll

RUN mkdir -p /var/jekyll
RUN mkdir -p /srv/jekyll
RUN chown -R jekyll:jekyll /srv/jekyll
RUN chown -R jekyll:jekyll /var/jekyll
RUN rm -rf /home/jekyll/.gem
RUN rm -rf /usr/gem/cache
RUN rm -rf /root/.gem

# The below pertains to an issue with the bundler package manager. We don't currently use it in this image,
# but we'll leave it commented out in case it's needed again someday.
#
# # Work around rubygems/rubygems#3572
# RUN mkdir -p /usr/gem/cache/bundle
# RUN chown -R jekyll:jekyll \
#   /usr/gem/cache/bundle

CMD ["jekyll", "--help"]
ENTRYPOINT ["/usr/jekyll/bin/entrypoint"]
WORKDIR /srv/jekyll
VOLUME  /srv/jekyll
EXPOSE 35729
EXPOSE 4000
